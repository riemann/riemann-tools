# frozen_string_literal: true

require 'riemann/tools'

module Riemann
  module Tools
    class Mesos
      include Riemann::Tools

      require 'faraday'
      require 'json'
      require 'uri'

      opt :read_timeout, 'Faraday read timeout', type: :int, default: 2
      opt :open_timeout, 'Faraday open timeout', type: :int, default: 1
      opt :path_prefix,
          'Mesos path prefix for proxied installations e.g. "mesos" for target http://localhost/mesos/metrics/snapshot', default: '/'.dup
      opt :mesos_host, 'Mesos host', default: 'localhost'
      opt :mesos_port, 'Mesos port', type: :int, default: 5050

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
            service: 'mesos health',
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
        "http://#{options[:mesos_host]}:#{options[:mesos_port]}#{path_prefix.length.positive? ? '/' : ''}#{path_prefix}/metrics/snapshot"
      end

      def slaves_url
        path_prefix = options[:path_prefix]
        path_prefix[0] = '' if path_prefix[0] == '/'
        path_prefix[path_prefix.length - 1] = '' if path_prefix[path_prefix.length - 1] == '/'
        "http://#{options[:mesos_host]}:#{options[:mesos_port]}#{path_prefix.length.positive? ? '/' : ''}#{path_prefix}/master/slaves"
      end

      def tick
        tick_slaves
        uri = URI(health_url)
        response = safe_get(uri)

        return if response.nil?

        if response.status != 200
          report(
            host: uri.host,
            service: 'mesos health',
            state: 'critical',
            description: "HTTP connection error: #{response.status} - #{response.body}",
          )
        else
          # Assuming that a 200 will give json
          json = JSON.parse(response.body)
          state = 'ok'

          report(
            host: uri.host,
            service: 'mesos health',
            state: state,
          )

          json.each_pair do |k, v|
            report(
              host: uri.host,
              service: "mesos #{k}",
              metric: v,
            )
          end
        end
      end

      def tick_slaves
        uri = URI(slaves_url)
        response = safe_get(uri)

        return if response.nil?

        if response.status != 200
          report(
            host: uri.host,
            service: 'mesos health',
            state: 'critical',
            description: "HTTP connection error: #{response.status} - #{response.body}",
          )
        else
          # Assuming that a 200 will give json
          json = JSON.parse(response.body)
          state = 'ok'

          report(
            host: uri.host,
            service: 'mesos health',
            state: state,
          )

          json['slaves'].each do |slave|
            next unless slave.respond_to? 'each_pair'

            slave.each_pair do |k, v|
              if v.respond_to? 'each_pair'
                v.each_pair do |k1, v1|
                  next unless v1.is_a? Numeric

                  report(
                    host: slave['hostname'],
                    service: "mesos slave/#{k}/#{k1}",
                    metric: v1,
                  )
                end
              elsif v.is_a? Numeric
                report(
                  host: slave['hostname'],
                  service: "mesos slave/#{k}",
                  metric: v,
                )
              end
            end
          end
        end
      end
    end
  end
end
