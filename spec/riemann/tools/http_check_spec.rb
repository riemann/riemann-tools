# frozen_string_literal: true

require 'openssl'
require 'rack/handler/webrick'
require 'sinatra/base'
require 'webrick'
require 'webrick/https'

require 'riemann/tools/http_check'

class TestWebserver < Sinatra::Base
  def authorized?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == %w[admin secret]
  end

  def protected!
    return if authorized?

    response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
    throw(:halt, [401, "Oops... we need your login name & password\n"])
  end

  get '/' do
    'ok'
  end

  get '/protected' do
    protected!
    'ok'
  end

  get '/slow' do
    sleep(0.5)
    'ok'
  end

  get '/sloww' do
    sleep(1)
    'ok'
  end

  get '/slowww' do
    sleep(10)
    'ok'
  end

  get '/rand' do
    SecureRandom.hex(16)
  end

  get '/redirect/same-origin' do
    redirect '/', 301
  end

  get '/redirect/other-origin' do
    redirect 'https://riemann.io/', 301
  end

  get '/redirect/same-origin-broken/:n' do
    redirect "/redirect/same-origin-broken/#{params[:n].to_i + 1}", 301
  end
end

RSpec.describe Riemann::Tools::HttpCheck, if: Gem::Version.new(RUBY_VERSION) >= Gem::Version.new(Riemann::Tools::HttpCheck::REQUIRED_RUBY_VERSION) do
  describe '#endpoint_name' do
    subject { described_class.new.endpoint_name(address, port) }
    let(:port) { 443 }

    context 'when using an IPv4 address' do
      let(:address) { IPAddr.new('127.0.0.1') }

      it { is_expected.to eq('127.0.0.1:443') }
    end

    context 'when using an IPv6 address' do
      let(:address) { IPAddr.new('::1') }

      it { is_expected.to eq('[::1]:443') }
    end
  end

  describe '#test_uri_addresses' do
    before do
      subject.options[:http_timeout] = http_timeout
      allow(subject).to receive(:report)
      subject.test_uri_addresses(uri, addresses)
    end

    let(:addresses) { ['::1', '127.0.0.1'] }

    let(:http_timeout) { 2.0 }

    context 'when using unencrypted http' do
      before(:all) do
        server_options = {
          Port: 0,
          StartCallback: -> { @started = true },
          AccessLog: [],
          Logger: WEBrick::Log.new(File.open(File::NULL, 'w')),
        }
        @server = WEBrick::HTTPServer.new(server_options)
        @server.mount('/', Rack::Handler::WEBrick, TestWebserver)
        @started = false
        Thread.new { @server.start }
        Timeout.timeout(1) { sleep(0.1) until @started }
      end

      after(:all) do
        @server&.shutdown
      end

      let(:test_webserver_port) { @server.config[:Port] }

      let(:reported_uri) { uri }

      context 'with a fast uri' do
        let(:uri) { URI("http://example.com:#{test_webserver_port}/") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/ [::1]:#{test_webserver_port} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/ [::1]:#{test_webserver_port} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/ [::1]:#{test_webserver_port} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/ 127.0.0.1:#{test_webserver_port} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/ 127.0.0.1:#{test_webserver_port} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/ 127.0.0.1:#{test_webserver_port} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/ consistency", state: 'ok', description: 'consistent response on all 2 endpoints' })) }
      end

      context 'with a slow uri' do
        let(:uri) { URI("http://example.com:#{test_webserver_port}/slow") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/slow [::1]:#{test_webserver_port} response latency", state: 'warning' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/slow 127.0.0.1:#{test_webserver_port} response latency", state: 'warning' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/slow consistency", state: 'ok', description: 'consistent response on all 2 endpoints' })) }
      end

      context 'with a very slow uri' do
        let(:uri) { URI("http://example.com:#{test_webserver_port}/sloww") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/sloww [::1]:#{test_webserver_port} response latency", state: 'critical' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/sloww 127.0.0.1:#{test_webserver_port} response latency", state: 'critical' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/sloww consistency", state: 'ok', description: 'consistent response on all 2 endpoints' })) }
      end

      context 'with a too slow uri' do
        let(:uri) { URI("http://example.com:#{test_webserver_port}/slowww") }
        let(:http_timeout) { 0.1 }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/slowww [::1]:#{test_webserver_port} response latency", state: 'critical', description: 'timeout' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/slowww 127.0.0.1:#{test_webserver_port} response latency", state: 'critical', description: 'timeout' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/slowww consistency", state: 'critical', description: 'Could not get any response from example.com' })) }
      end

      context 'with inconsistent responses' do
        let(:uri) { URI("http://example.com:#{test_webserver_port}/rand") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/rand [::1]:#{test_webserver_port} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/rand [::1]:#{test_webserver_port} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/rand [::1]:#{test_webserver_port} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/rand 127.0.0.1:#{test_webserver_port} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/rand 127.0.0.1:#{test_webserver_port} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/rand 127.0.0.1:#{test_webserver_port} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/rand consistency", state: 'critical', description: '2 different response body on 2 endpoints' })) }
      end

      context 'with basic authentication and a good password' do
        let(:uri) { URI("http://admin:secret@example.com:#{test_webserver_port}/protected") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{test_webserver_port}/protected [::1]:#{test_webserver_port} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{test_webserver_port}/protected [::1]:#{test_webserver_port} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{test_webserver_port}/protected [::1]:#{test_webserver_port} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{test_webserver_port}/protected 127.0.0.1:#{test_webserver_port} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{test_webserver_port}/protected 127.0.0.1:#{test_webserver_port} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{test_webserver_port}/protected 127.0.0.1:#{test_webserver_port} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{test_webserver_port}/protected consistency", state: 'ok', description: 'consistent response on all 2 endpoints' })) }
      end

      context 'with basic authentication and a wrong password' do
        let(:uri) { URI("http://admin:wrong-password@example.com:#{test_webserver_port}/protected") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{test_webserver_port}/protected [::1]:#{test_webserver_port} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{test_webserver_port}/protected [::1]:#{test_webserver_port} response code", metric: 401, state: 'ok', description: '401 Unauthorized' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{test_webserver_port}/protected [::1]:#{test_webserver_port} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{test_webserver_port}/protected 127.0.0.1:#{test_webserver_port} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{test_webserver_port}/protected 127.0.0.1:#{test_webserver_port} response code", metric: 401, state: 'ok', description: '401 Unauthorized' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{test_webserver_port}/protected 127.0.0.1:#{test_webserver_port} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{test_webserver_port}/protected consistency", state: 'ok', description: 'consistent response on all 2 endpoints' })) }
      end

      context 'with an IPv4 address' do
        let(:uri) { URI("http://127.0.0.1:#{test_webserver_port}/") }
        let(:addresses) { ['127.0.0.1'] }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://127.0.0.1:#{test_webserver_port}/ 127.0.0.1:#{test_webserver_port} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://127.0.0.1:#{test_webserver_port}/ 127.0.0.1:#{test_webserver_port} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://127.0.0.1:#{test_webserver_port}/ 127.0.0.1:#{test_webserver_port} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://127.0.0.1:#{test_webserver_port}/ consistency", state: 'ok', description: 'consistent response on all 1 endpoints' })) }
      end

      context 'with an IPv6 address' do
        let(:uri) { URI("http://[::1]:#{test_webserver_port}/") }
        let(:addresses) { ['::1'] }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://[::1]:#{test_webserver_port}/ [::1]:#{test_webserver_port} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://[::1]:#{test_webserver_port}/ [::1]:#{test_webserver_port} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://[::1]:#{test_webserver_port}/ [::1]:#{test_webserver_port} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://[::1]:#{test_webserver_port}/ consistency", state: 'ok', description: 'consistent response on all 1 endpoints' })) }
      end

      context 'when a same-origin redirect is found' do
        let(:uri) { URI("http://example.com:#{test_webserver_port}/redirect/same-origin") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/redirect/same-origin 127.0.0.1:#{test_webserver_port} response code", metric: 301, state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/ 127.0.0.1:#{test_webserver_port} response code", metric: 200, state: 'ok' })) }
      end

      context 'when an other-origin redirect is found' do
        let(:uri) { URI("http://example.com:#{test_webserver_port}/redirect/other-origin") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/redirect/other-origin 127.0.0.1:#{test_webserver_port} response code", metric: 301, state: 'ok' })) }
        it { is_expected.not_to have_received(:report).with(hash_including({ metric: 200, state: 'ok' })) }
      end

      context 'when an same-origin-broken redirect is found' do
        let(:uri) { URI("http://example.com:#{test_webserver_port}/redirect/same-origin-broken/0") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/redirect/same-origin-broken/0 127.0.0.1:#{test_webserver_port} response code", metric: 301, state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/redirect/same-origin-broken/1 127.0.0.1:#{test_webserver_port} response code", metric: 301, state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/redirect/same-origin-broken/2 127.0.0.1:#{test_webserver_port} response code", metric: 301, state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/redirect/same-origin-broken/3 127.0.0.1:#{test_webserver_port} response code", metric: 301, state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/redirect/same-origin-broken/4 127.0.0.1:#{test_webserver_port} response code", metric: 301, state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/redirect/same-origin-broken/5 127.0.0.1:#{test_webserver_port} response code", metric: 301, state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/redirect/same-origin-broken/5 127.0.0.1:#{test_webserver_port} redirects", state: 'critical', description: 'Reached the limit of 5 redirects' })) }
        it { is_expected.not_to have_received(:report).with(hash_including({ service: "get http://example.com:#{test_webserver_port}/redirect/same-origin-broken/6 127.0.0.1:#{test_webserver_port} response code", metric: 301, state: 'ok' })) }
      end
    end

    context 'when using encrypted https' do
      before(:all) do
        server_options = {
          Port: 0,
          StartCallback: -> { @started = true },
          AccessLog: [],
          Logger: WEBrick::Log.new(File.open(File::NULL, 'w')),
          SSLEnable: true,
          SSLCertName: '/CN=example.com',
        }
        @server = WEBrick::HTTPServer.new(server_options)
        @server.mount('/', Rack::Handler::WEBrick, TestWebserver)
        @started = false
        Thread.new { @server.start }
        Timeout.timeout(1) { sleep(0.1) until @started }
      end

      let(:test_webserver_port) { @server.config[:Port] }

      after(:all) do
        @server&.shutdown
      end

      context 'with an encrypted uri' do
        let(:uri) { URI("https://example.com:#{test_webserver_port}/") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get https://example.com:#{test_webserver_port}/ [::1]:#{test_webserver_port} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get https://example.com:#{test_webserver_port}/ [::1]:#{test_webserver_port} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get https://example.com:#{test_webserver_port}/ [::1]:#{test_webserver_port} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get https://example.com:#{test_webserver_port}/ 127.0.0.1:#{test_webserver_port} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get https://example.com:#{test_webserver_port}/ 127.0.0.1:#{test_webserver_port} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get https://example.com:#{test_webserver_port}/ 127.0.0.1:#{test_webserver_port} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get https://example.com:#{test_webserver_port}/ consistency", state: 'ok', description: 'consistent response on all 2 endpoints' })) }
      end
    end

    context 'with a wrong port' do
      let(:uri) { URI('http://example.com:23/') }

      it { is_expected.to have_received(:report).with(hash_including({ service: 'get http://example.com:23/ consistency', state: 'critical', description: 'Could not get any response from example.com' })) }
    end

    context 'with a wrong domain' do
      let(:uri) { URI('https://invalid.example.com/') }

      it { is_expected.to have_received(:report).with(hash_including({ service: 'get https://invalid.example.com/ consistency', state: 'critical', description: 'Could not get any response from invalid.example.com' })) }
    end
  end
end
