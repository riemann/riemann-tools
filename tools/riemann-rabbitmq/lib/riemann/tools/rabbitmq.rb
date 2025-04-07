# frozen_string_literal: true

require 'riemann/tools'

module Riemann
  module Tools
    class Rabbitmq
      include Riemann::Tools

      require 'faraday'
      require 'json'
      require 'uri'

      opt :read_timeout, 'Faraday read timeout', type: :int, default: 2
      opt :open_timeout, 'Faraday open timeout', type: :int, default: 1

      opt :monitor_user, 'RabbitMQ monitoring user', type: :string
      opt :monitor_pass, 'RabbitMQ monitoring user password', type: :string
      opt :monitor_port, 'RabbitMQ monitoring port', type: :int, default: 15_672
      opt :monitor_host, 'RabbitMQ monitoring host', type: :string, default: 'localhost'
      opt :monitor_use_tls, 'RabbitMQ use tls', type: :bool, default: false

      opt :max_queue_size, 'max number of items in a queue that is acceptable', type: :int, default: 1_000_000
      opt :ignore_max_size_queues, "A regular expression to match queues that shouldn't be size-checked", type: :string

      opt :node, 'Specify a node to monitor', type: :strings

      def base_url
        protocol = 'http'
        protocol = 'https' if opts[:monitor_use_tls] && (opts[:monitor_use_tls] == true)
        "#{protocol}://#{opts[:monitor_user]}:#{opts[:monitor_pass]}@#{opts[:monitor_host]}:#{opts[:monitor_port]}/api"
      end

      def overview_url
        "#{base_url}/overview"
      end

      def node_url(node)
        "#{base_url}/nodes/#{node}"
      end

      def queues_url
        "#{base_url}/queues"
      end

      def event_host
        opts[:event_host] || :monitor_host
      end

      def safe_get(uri, event_host)
        # Handle connection timeouts
        response = nil
        begin
          connection = Faraday.new(uri)
          response = connection.get do |req|
            req.opts[:timeout] = opts[:read_timeout]
            req.opts[:open_timeout] = opts[:open_timeout]
          end
          report(
            host: event_host,
            service: 'rabbitmq monitoring',
            state: 'ok',
            description: 'Monitoring operational',
          )
        rescue StandardError => e
          report(
            host: event_host,
            service: 'rabbitmq monitoring',
            state: 'critical',
            description: "HTTP connection error: #{e.class} - #{e.message}",
          )
        end
        response
      end

      def check_queues
        response = safe_get(queues_url, event_host)
        max_size_check_filter = (Regexp.new(opts[:ignore_max_size_queues]) if opts[:ignore_max_size_queues])

        return if response.nil?

        if response.status != 200
          report(
            host: event_host,
            service: 'rabbitmq.queue',
            state: 'critical',
            description: "HTTP connection error to /api/queues: #{response.status} - #{response.body}",
          )
        else
          report(
            host: event_host,
            service: 'rabbitmq.queue',
            state: 'ok',
            description: 'HTTP connection ok',
          )

          json = JSON.parse(response.body)

          json.each do |queue|
            svc = "rabbitmq.queue.#{queue['vhost']}.#{queue['name']}"
            errs = []

            errs << 'Queue has jobs but no consumers' if !queue['messages_ready'].nil? && queue['messages_ready'].positive? && queue['consumers'].zero?

            errs << "Queue has #{queue['messages_ready']} jobs" if (max_size_check_filter.nil? || queue['name'] !~ (max_size_check_filter)) && !queue['messages_ready'].nil? && (queue['messages_ready'] > opts[:max_queue_size])

            if errs.empty?
              report(
                host: event_host,
                service: svc,
                state: 'ok',
                description: 'Queue is looking good',
              )
            else
              report(
                host: event_host,
                service: svc,
                state: 'critical',
                description: errs.join('; '),
              )
            end

            stats = (queue['message_stats'] || {}).merge(
              'messages'                        => queue['messages'],
              'messages_details'                => queue['messages_details'],
              'messages_ready'                  => queue['messages_ready'],
              'messages_ready_details'          => queue['messages_ready_details'],
              'messages_unacknowledged'         => queue['messages_unacknowledged'],
              'messages_unacknowledged_details' => queue['messages_unacknowledged_details'],
              'consumers'                       => queue['consumers'],
              'memory'                          => queue['memory'],
            )

            stats.each_pair do |k, v|
              service = "#{svc}.#{k}"
              metric = if k =~ (/details$/) && !v.nil?
                         v['rate']
                       else
                         v
                       end

              # TODO: Set state via thresholds which can be configured

              report(
                host: event_host,
                service: service,
                metric: metric,
                description: 'RabbitMQ monitor',
              )
            end
          end
        end
      end

      def check_overview
        uri = URI(overview_url)
        response = safe_get(uri, event_host)

        return if response.nil?

        json = JSON.parse(response.body)

        if response.status != 200
          report(
            host: event_host,
            service: 'rabbitmq',
            state: 'critical',
            description: "HTTP connection error: #{response.status} - #{response.body}",
          )
        else
          report(
            host: event_host,
            service: 'rabbitmq monitoring',
            state: 'ok',
            description: 'HTTP connection ok',
          )

          %w[message_stats queue_totals object_totals].each do |stat|
            # NOTE: / BUG ?
            # Brand new servers can have blank message stats. Is this ok?
            # I can't decide.
            next if json[stat].empty?

            json[stat].each_pair do |k, v|
              service = "rabbitmq.#{stat}.#{k}"
              metric = if k =~ /details$/
                         v['rate']
                       else
                         v
                       end

              # TODO: Set state via thresholds which can be configured

              report(
                host: event_host,
                service: service,
                metric: metric,
                description: 'RabbitMQ monitor',
              )
            end
          end
        end
      end

      def check_node
        opts[:node].each do |n|
          uri = URI(node_url(n))
          response = safe_get(uri, event_host)

          break if response.nil?

          if response.status != 200
            if response.status == 404
              report(
                host: event_host,
                service: "rabbitmq.node.#{n}",
                state: 'critical',
                description: 'Node was not found in the cluster',
              )
            else
              report(
                host: event_host,
                service: "rabbitmq.node.#{n}",
                state: 'critical',
                description: "HTTP error: #{response.status} - #{response.body}",
              )
            end
            break
          end

          json = JSON.parse(response.body)

          if json['mem_alarm']
            report(
              host: event_host,
              service: "rabbitmq.node.#{n}",
              state: 'critical',
              description: 'Memory alarm has triggered; job submission throttled',
            )
            break
          end

          if json['disk_free_alarm']
            report(
              host: event_host,
              service: "rabbitmq.node.#{n}",
              state: 'critical',
              description: 'Disk free alarm has triggered; job submission throttled',
            )
            break
          end

          report(
            host: event_host,
            service: "rabbitmq.node.#{n}",
            state: 'ok',
            description: 'Node looks OK to me',
          )
        end
      end

      def tick
        check_overview
        check_node if opts[:node]
        check_queues
      end
    end
  end
end
