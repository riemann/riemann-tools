# frozen_string_literal: true

require 'singleton'

require 'riemann/client'

module Riemann
  module Tools
    class RiemannClientWrapper
      include Singleton

      BACKOFF_TMIN = 0.5  # Minimum delay between reconnection attempts
      BACKOFF_TMAX = 30.0 # Maximum delay
      BACKOFF_FACTOR = 2

      # The wrapper manage a single connection to riemann, transport options
      # cannot be adjusted when riemann-wrapper is running, and enqueing events
      # should not happen when the system is tearing down.  This is achieved
      # with this simple state machine
      #
      # [idle] --client--> [running] --drain--> [draining]
      #    ^                                         |
      #    +-------[#reset (development only)]-------+
      attr_reader :state

      STATE_IDLE = 1
      STATE_RUNNING = 2
      STATE_DRAINING = 3

      # These options are transport-related, and SHALL be the same for each
      # tool running in riemann-wrapper.  Other options are ignored as far as
      # the wrapper is concerned.
      ALLOWED_OPTIONS = %i[host port timeout tls tls_key tls_cert tls_ca_cert tls_verify tcp tls].freeze

      attr_reader :options

      def options=(options)
        if state == STATE_IDLE
          @options = options
          @client = nil
        else
          return if options.slice(*ALLOWED_OPTIONS) == @options.slice(*ALLOWED_OPTIONS)

          raise 'Cannot change options while running'
        end
      end

      def initialize
        @options = nil
        @queue = Queue.new
        @max_bulk_size = 1000
        @state = STATE_IDLE

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
          @state = STATE_RUNNING

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
        raise('Cannot queue events while draining') if state == STATE_DRAINING

        @queue << event
      end

      def drain
        @state = STATE_DRAINING
        sleep(1) until @queue.empty? || @worker.stop?
      end

      private

      # For development purpose only: we do not want the singleton to leak
      # state from one test to another.
      def reset
        @options = nil
        @queue.clear
        @state = STATE_IDLE
      end
    end
  end
end
