# frozen_string_literal: true

require 'singleton'

require 'riemann/client'

module Riemann
  module Tools
    class RiemannClientWrapper
      attr_reader :options

      BACKOFF_TMIN = 0.5  # Minimum delay between reconnection attempts
      BACKOFF_TMAX = 30.0 # Maximum delay
      BACKOFF_FACTOR = 2

      def initialize(options)
        @options = options

        @queue = Queue.new
        @max_bulk_size = 1000
        @draining = false

        @worker = Thread.new do
          Thread.current.abort_on_exception = true
          backoff_delay = BACKOFF_TMIN

          loop do
            events = []

            events << @queue.pop
            events << @queue.pop while !@queue.empty? && events.size < @max_bulk_size

            client.bulk_send(events)
            backoff_delay = BACKOFF_TMIN
          rescue StandardError => e
            sleep(backoff_delay)

            dropped_count = events.size + @queue.size
            @queue.clear
            warn "Dropped #{dropped_count} event#{'s' if dropped_count > 1} due to #{e}"

            backoff_delay *= BACKOFF_FACTOR
            backoff_delay = BACKOFF_TMAX if backoff_delay > BACKOFF_TMAX
          end
        end

        at_exit { drain }
      end

      def client
        @client ||= begin
          r = Riemann::Client.new(
            host: options[:host],
            port: options[:port],
            timeout: options[:timeout],
            ssl: options[:tls],
            key_file: options[:tls_key],
            cert_file: options[:tls_cert],
            ca_file: options[:tls_ca_cert],
            ssl_verify: options[:tls_verify],
          )

          if options[:tcp] || options[:tls]
            r.tcp
          else
            r
          end
        end
      end

      def <<(event)
        raise('Cannot queue events when draining') if @draining

        @queue << event
      end

      def drain
        @draining = true
        sleep(1) until @queue.empty? || @worker.stop?
      end
    end
  end
end
