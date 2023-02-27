# frozen_string_literal: true

require 'singleton'

require 'riemann/client'

module Riemann
  module Tools
    class RiemannClientWrapper
      attr_reader :options

      def initialize(options)
        @options = options

        @queue = Queue.new
        @max_bulk_size = 1000
        @draining = false

        @worker = Thread.new do
          Thread.current.abort_on_exception = true
          loop do
            events = []

            events << @queue.pop
            events << @queue.pop while !@queue.empty? && events.size < @max_bulk_size

            client.bulk_send(events)
          rescue Riemann::Client::Error => e
            warn "Dropping #{events.size} event#{'s' if events.size > 1} due to #{e}"
          rescue StandardError => e
            warn "#{e.class} #{e}\n#{e.backtrace.join "\n"}"
            Thread.main.terminate
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
