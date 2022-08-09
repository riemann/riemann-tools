# frozen_string_literal: true

require 'riemann/tools'

module Riemann
  module Tools
    class Chronos
      include Riemann::Tools

      require 'faraday'
      require 'json'
      require 'uri'

      opt :read_timeout, 'Faraday read timeout', type: :int, default: 2
      opt :open_timeout, 'Faraday open timeout', type: :int, default: 1
      opt :path_prefix,
          'Chronos path prefix for proxied installations e.g. "chronos" for target http://localhost/chronos/metrics', default: '/'.dup
      opt :chronos_host, 'Chronos host', default: 'localhost'
      opt :chronos_port, 'Chronos port', type: :int, default: 4400

      def initialize
        options[:interval] = 60
        options[:ttl] = 120
      end

      # Handles HTTP connections and GET requests safely
      def safe_get(uri)
        # Handle connection timeouts
        response = nil
        begin
          connection = Faraday.new(uri)
          response = connection.get do |req|
            req.options[:timeout] = options[:read_timeout]
            req.options[:open_timeout] = options[:open_timeout]
          end
        rescue StandardError => e
          report(
            host: uri.host,
            service: 'chronos health',
            state: 'critical',
            description: "HTTP connection error: #{e.class} - #{e.message}",
          )
        end
        response
      end

      def health_url
        path_prefix = options[:path_prefix]
        path_prefix[0] = '' if path_prefix[0] == '/'
        path_prefix[path_prefix.length - 1] = '' if path_prefix[path_prefix.length - 1] == '/'
        "http://#{options[:chronos_host]}:#{options[:chronos_port]}#{path_prefix.length.positive? ? '/' : ''}#{path_prefix}/metrics"
      end

      def jobs_url
        path_prefix = options[:path_prefix]
        path_prefix[0] = '' if path_prefix[0] == '/'
        path_prefix[path_prefix.length - 1] = '' if path_prefix[path_prefix.length - 1] == '/'
        "http://#{options[:chronos_host]}:#{options[:chronos_port]}#{path_prefix.length.positive? ? '/' : ''}#{path_prefix}/scheduler/jobs"
      end

      def tick
        tick_health
        tick_jobs
      end

      def tick_health
        uri = URI(health_url)
        response = safe_get(uri)

        return if response.nil?

        if response.status != 200
          report(
            host: uri.host,
            service: 'chronos health',
            state: 'critical',
            description: "HTTP connection error: #{response.status} - #{response.body}",
          )
        else
          # Assuming that a 200 will give json
          json = JSON.parse(response.body)

          report(
            host: uri.host,
            service: 'chronos health',
            state: 'ok',
          )

          json.each_pair do |t, d|
            next unless d.respond_to? :each_pair

            d.each_pair do |service, counters|
              report(
                host: uri.host,
                service: "chronos_metric #{t} #{service}",
                metric: 1,
                tags: ['metric_name'],
                ttl: 600,
              )
              next unless counters.respond_to? :each_pair

              counters.each_pair do |k, v|
                next unless v.is_a? Numeric

                report(
                  host: uri.host,
                  service: "chronos #{service} #{k}",
                  metric: v,
                  tags: ['metric', t.to_s],
                  ttl: 600,
                )
              end
            end
          end
        end
      end

      def tick_jobs
        uri = URI(jobs_url)
        response = safe_get(uri)

        return if response.nil?

        if response.status != 200
          report(
            host: uri.host,
            service: 'chronos health',
            state: 'critical',
            description: "HTTP connection error: #{response.status} - #{response.body}",
          )
        else
          # Assuming that a 200 will give json
          json = JSON.parse(response.body)

          report(
            host: uri.host,
            service: 'chronos health',
            state: 'ok',
          )

          json.each do |job|
            job.each_pair do |k, v|
              next unless v.is_a? Numeric

              report(
                host: uri.host,
                service: "chronos job #{job['name']} #{k}",
                metric: v,
                ttl: 120,
              )
            end
          end
        end
      end
    end
  end
end
