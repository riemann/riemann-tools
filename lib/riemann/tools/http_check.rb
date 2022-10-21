# frozen_string_literal: true

require 'net/http'
require 'resolv'
require 'socket'

require 'riemann/tools'

# Test for HTTP requests
module Riemann
  module Tools
    class HttpCheck
      include Riemann::Tools

      opt :uri, 'URI to fetch', short: :none, type: :strings, default: ['http://localhost']
      opt :response, 'Expected response codes', short: :none, type: :strings, default: [
        '200', # OK
        '301', # Moved Permanently
        '401', # Unauthorized
      ]
      opt :connection_latency_warning, 'Lattency warning threshold', short: :none, default: 0.1
      opt :connection_latency_critical, 'Lattency critical threshold', short: :none, default: 0.25
      opt :response_latency_warning, 'Lattency warning threshold', short: :none, default: 0.5
      opt :response_latency_critical, 'Lattency critical threshold', short: :none, default: 1.0
      opt :http_timeout, 'Timeout (in seconds) for HTTP requests', short: :none, default: 5.0
      opt :checks, 'A list of checks to run.', short: :none, type: :strings, default: %w[consistency connection-latency response-code response-latency]

      def tick
        opts[:uri].each do |uri|
          test_uri(uri)
        end
      end

      def test_uri(uri)
        uri = URI(uri)

        request = ::Net::HTTP::Get.new(uri)
        request.basic_auth(uri.user, uri.password)

        responses = []

        with_each_address(uri.host) do |address|
          responses << test_uri_address(uri, address, request)
        end

        responses.compact!

        return unless opts[:checks].include?('consistency')

        raise StandardError, "Could not get any response from #{uri.host}" unless responses.any?

        uniq_code = responses.map(&:code).uniq
        uniq_body = responses.map(&:body).uniq

        issues = []
        issues << "#{uniq_code.count} different response code" unless uniq_code.one?
        issues << "#{uniq_body.count} different response body" unless uniq_body.one?

        if issues.none?
          state = 'ok'
          description = "consistent response on all #{responses.count} endpoints"
        else
          state = 'critical'
          description = "#{issues.join(' and ')} on #{responses.count} endpoints"
        end

        report(
          service: service(uri, 'consistency'),
          state: state,
          description: description,
          hostname: uri.host,
          port: uri.port,
        )
      rescue StandardError => e
        report(
          service: service(uri, 'consistency'),
          state: 'critical',
          description: e.message,
          hostname: uri.host,
          port: uri.port,
        )
      end

      def test_uri_address(uri, address, request)
        response = nil

        start = Time.now
        connected = nil
        done = nil

        http = nil
        begin
          Timeout.timeout(opts[:http_timeout]) do
            http = ::Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE, ipaddr: address)
            connected = Time.now
            response = http.request(request)
          end
        rescue Timeout::Error
          # Ignore
        else
          done = Time.now
        ensure
          http&.finish
        end

        report_http_endpoint_response_code(http, uri, response) if opts[:checks].include?('response-code')
        report_http_endpoint_latency(http, uri, 'connection', start, connected) if opts[:checks].include?('connection-latency')
        report_http_endpoint_latency(http, uri, 'response', start, done) if opts[:checks].include?('response-latency')

        response
      rescue StandardError
        # Ignore this address
        nil
      end

      def with_each_address(host, &block)
        addresses = Resolv::DNS.new.getaddresses(host)
        if addresses.empty?
          host = host[1...-1] if host[0] == '[' && host[-1] == ']'
          addresses << IPAddr.new(host)
        end

        addresses.each do |address|
          block.call(address.to_s)
        end
      end

      def report_http_endpoint_response_code(http, uri, response)
        return unless response

        report(
          {
            state: response_code_state(response.code),
            metric: response.code.to_i,
            description: "#{response.code} #{response.message}",
          }.merge(endpoint_report(http, uri, 'response code')),
        )
      end

      def response_code_state(code)
        opts[:response].include?(code) ? 'ok' : 'critical'
      end

      def report_http_endpoint_latency(http, uri, latency, start, stop)
        if stop
          metric = stop - start
          report(
            {
              state: latency_state(latency, metric),
              metric: metric,
              description: format('%.3f ms', metric * 1000),
            }.merge(endpoint_report(http, uri, "#{latency} latency")),
          )
        else
          report(
            {
              state: 'critical',
              description: 'timeout',
            }.merge(endpoint_report(http, uri, "#{latency} latency")),
          )
        end
      end

      def latency_state(name, latency)
        if latency > opts["#{name}_latency_critical".to_sym]
          'critical'
        elsif latency > opts["#{name}_latency_warning".to_sym]
          'warning'
        else
          'ok'
        end
      end

      def endpoint_report(http, uri, service)
        {
          service: endpoint_service(http, uri, service),
          hostname: uri.host,
          address: http.ipaddr,
          port: uri.port,
        }
      end

      def endpoint_service(http, uri, service)
        "get #{redact_uri(uri)} #{endpoint_name(IPAddr.new(http.ipaddr), http.port)} #{service}"
      end

      def service(uri, service)
        "get #{redact_uri(uri)} #{service}"
      end

      def redact_uri(uri)
        reported_uri = uri.dup
        reported_uri.password = '**redacted**' if reported_uri.password
        reported_uri
      end

      def endpoint_name(address, port)
        if address.ipv6?
          "[#{address}]:#{port}"
        else
          "#{address}:#{port}"
        end
      end
    end
  end
end
