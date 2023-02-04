# frozen_string_literal: true

require 'singleton'

require 'riemann/client'

module Riemann
  module Tools
    class RiemannClientWrapper
      include Singleton

      def initialize
        @client = nil
        @queue = Queue.new
        @max_bulk_size = 1000
      end

      def configure(options)
        return self unless @client.nil?

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

        @client = if options[:tcp] || options[:tls]
                    r.tcp
                  else
                    r
                  end

        @worker = Thread.new do
          loop do
            events = []

            events << @queue.pop
            events << @queue.pop while !@queue.empty? && events.size < @max_bulk_size

            @client.bulk_send(events)
          end
        end
        @worker.abort_on_exception = true

        at_exit { drain }

        self
      end

      def <<(event)
        @queue << event
      end

      def drain
        sleep(1) until @queue.empty?
      end
    end
  end
end
