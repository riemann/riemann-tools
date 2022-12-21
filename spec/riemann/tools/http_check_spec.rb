# frozen_string_literal: true

require 'openssl'
require 'rack/handler/webrick'
require 'sinatra/base'
require 'webrick'
require 'webrick/https'

require 'riemann/tools/http_check'

TEST_WEBSERVER_PORT = 65_391

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
          Port: TEST_WEBSERVER_PORT,
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

      let(:reported_uri) { uri }

      context 'with a fast uri' do
        let(:uri) { URI("http://example.com:#{TEST_WEBSERVER_PORT}/") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/ [::1]:#{TEST_WEBSERVER_PORT} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/ [::1]:#{TEST_WEBSERVER_PORT} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/ [::1]:#{TEST_WEBSERVER_PORT} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/ 127.0.0.1:#{TEST_WEBSERVER_PORT} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/ 127.0.0.1:#{TEST_WEBSERVER_PORT} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/ 127.0.0.1:#{TEST_WEBSERVER_PORT} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/ consistency", state: 'ok', description: 'consistent response on all 2 endpoints' })) }
      end

      context 'with a slow uri' do
        let(:uri) { URI("http://example.com:#{TEST_WEBSERVER_PORT}/slow") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/slow [::1]:#{TEST_WEBSERVER_PORT} response latency", state: 'warning' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/slow 127.0.0.1:#{TEST_WEBSERVER_PORT} response latency", state: 'warning' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/slow consistency", state: 'ok', description: 'consistent response on all 2 endpoints' })) }
      end

      context 'with a very slow uri' do
        let(:uri) { URI("http://example.com:#{TEST_WEBSERVER_PORT}/sloww") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/sloww [::1]:#{TEST_WEBSERVER_PORT} response latency", state: 'critical' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/sloww 127.0.0.1:#{TEST_WEBSERVER_PORT} response latency", state: 'critical' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/sloww consistency", state: 'ok', description: 'consistent response on all 2 endpoints' })) }
      end

      context 'with a too slow uri' do
        let(:uri) { URI("http://example.com:#{TEST_WEBSERVER_PORT}/slowww") }
        let(:http_timeout) { 0.1 }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/slowww [::1]:#{TEST_WEBSERVER_PORT} response latency", state: 'critical', description: 'timeout' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/slowww 127.0.0.1:#{TEST_WEBSERVER_PORT} response latency", state: 'critical', description: 'timeout' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/slowww consistency", state: 'critical', description: 'Could not get any response from example.com' })) }
      end

      context 'with inconsistent responses' do
        let(:uri) { URI("http://example.com:#{TEST_WEBSERVER_PORT}/rand") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/rand [::1]:#{TEST_WEBSERVER_PORT} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/rand [::1]:#{TEST_WEBSERVER_PORT} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/rand [::1]:#{TEST_WEBSERVER_PORT} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/rand 127.0.0.1:#{TEST_WEBSERVER_PORT} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/rand 127.0.0.1:#{TEST_WEBSERVER_PORT} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/rand 127.0.0.1:#{TEST_WEBSERVER_PORT} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://example.com:#{TEST_WEBSERVER_PORT}/rand consistency", state: 'critical', description: '2 different response body on 2 endpoints' })) }
      end

      context 'with basic authentication and a good password' do
        let(:uri) { URI("http://admin:secret@example.com:#{TEST_WEBSERVER_PORT}/protected") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{TEST_WEBSERVER_PORT}/protected [::1]:#{TEST_WEBSERVER_PORT} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{TEST_WEBSERVER_PORT}/protected [::1]:#{TEST_WEBSERVER_PORT} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{TEST_WEBSERVER_PORT}/protected [::1]:#{TEST_WEBSERVER_PORT} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{TEST_WEBSERVER_PORT}/protected 127.0.0.1:#{TEST_WEBSERVER_PORT} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{TEST_WEBSERVER_PORT}/protected 127.0.0.1:#{TEST_WEBSERVER_PORT} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{TEST_WEBSERVER_PORT}/protected 127.0.0.1:#{TEST_WEBSERVER_PORT} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{TEST_WEBSERVER_PORT}/protected consistency", state: 'ok', description: 'consistent response on all 2 endpoints' })) }
      end

      context 'with basic authentication and a wrong password' do
        let(:uri) { URI("http://admin:wrong-password@example.com:#{TEST_WEBSERVER_PORT}/protected") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{TEST_WEBSERVER_PORT}/protected [::1]:#{TEST_WEBSERVER_PORT} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{TEST_WEBSERVER_PORT}/protected [::1]:#{TEST_WEBSERVER_PORT} response code", metric: 401, state: 'ok', description: '401 Unauthorized' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{TEST_WEBSERVER_PORT}/protected [::1]:#{TEST_WEBSERVER_PORT} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{TEST_WEBSERVER_PORT}/protected 127.0.0.1:#{TEST_WEBSERVER_PORT} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{TEST_WEBSERVER_PORT}/protected 127.0.0.1:#{TEST_WEBSERVER_PORT} response code", metric: 401, state: 'ok', description: '401 Unauthorized' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{TEST_WEBSERVER_PORT}/protected 127.0.0.1:#{TEST_WEBSERVER_PORT} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://admin:**redacted**@example.com:#{TEST_WEBSERVER_PORT}/protected consistency", state: 'ok', description: 'consistent response on all 2 endpoints' })) }
      end

      context 'with an IPv4 address' do
        let(:uri) { URI("http://127.0.0.1:#{TEST_WEBSERVER_PORT}/") }
        let(:addresses) { ['127.0.0.1'] }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://127.0.0.1:#{TEST_WEBSERVER_PORT}/ 127.0.0.1:#{TEST_WEBSERVER_PORT} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://127.0.0.1:#{TEST_WEBSERVER_PORT}/ 127.0.0.1:#{TEST_WEBSERVER_PORT} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://127.0.0.1:#{TEST_WEBSERVER_PORT}/ 127.0.0.1:#{TEST_WEBSERVER_PORT} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://127.0.0.1:#{TEST_WEBSERVER_PORT}/ consistency", state: 'ok', description: 'consistent response on all 1 endpoints' })) }
      end

      context 'with an IPv6 address' do
        let(:uri) { URI("http://[::1]:#{TEST_WEBSERVER_PORT}/") }
        let(:addresses) { ['::1'] }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://[::1]:#{TEST_WEBSERVER_PORT}/ [::1]:#{TEST_WEBSERVER_PORT} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://[::1]:#{TEST_WEBSERVER_PORT}/ [::1]:#{TEST_WEBSERVER_PORT} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://[::1]:#{TEST_WEBSERVER_PORT}/ [::1]:#{TEST_WEBSERVER_PORT} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get http://[::1]:#{TEST_WEBSERVER_PORT}/ consistency", state: 'ok', description: 'consistent response on all 1 endpoints' })) }
      end
    end

    context 'when using encrypted https' do
      before(:all) do
        server_options = {
          Port: TEST_WEBSERVER_PORT,
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

      after(:all) do
        @server&.shutdown
      end

      context 'with an encrypted uri' do
        let(:uri) { URI("https://example.com:#{TEST_WEBSERVER_PORT}/") }

        it { is_expected.to have_received(:report).with(hash_including({ service: "get https://example.com:#{TEST_WEBSERVER_PORT}/ [::1]:#{TEST_WEBSERVER_PORT} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get https://example.com:#{TEST_WEBSERVER_PORT}/ [::1]:#{TEST_WEBSERVER_PORT} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get https://example.com:#{TEST_WEBSERVER_PORT}/ [::1]:#{TEST_WEBSERVER_PORT} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get https://example.com:#{TEST_WEBSERVER_PORT}/ 127.0.0.1:#{TEST_WEBSERVER_PORT} connection latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get https://example.com:#{TEST_WEBSERVER_PORT}/ 127.0.0.1:#{TEST_WEBSERVER_PORT} response code", metric: 200, state: 'ok', description: '200 OK' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get https://example.com:#{TEST_WEBSERVER_PORT}/ 127.0.0.1:#{TEST_WEBSERVER_PORT} response latency", state: 'ok' })) }
        it { is_expected.to have_received(:report).with(hash_including({ service: "get https://example.com:#{TEST_WEBSERVER_PORT}/ consistency", state: 'ok', description: 'consistent response on all 2 endpoints' })) }
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
