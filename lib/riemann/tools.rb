# frozen_string_literal: true

module Riemann
  module Tools
    require 'optimist'
    require 'riemann/tools/riemann_client_wrapper'

    def self.included(base)
      base.instance_eval do
        def run
          new.run
        end

        def opt(*args)
          args.unshift :opt
          @opts ||= []
          @opts << args
        end

        def options
          p = Optimist::Parser.new
          @opts.each do |o|
            p.send(*o)
          end
          Optimist.with_standard_exception_handling(p) do
            p.parse ARGV
          end
        end

        opt :host, 'Riemann host', default: '127.0.0.1'
        opt :port, 'Riemann port', default: 5555
        opt :event_host, 'Event hostname', type: String
        opt :interval, 'Seconds between updates', default: 5
        opt :tag, 'Tag to add to events', type: String, multi: true
        opt :ttl, 'TTL for events (twice the interval when unspecified)', type: Integer
        opt :minimum_ttl, 'Minimum TTL for events', type: Integer, short: :none
        opt :attribute, 'Attribute to add to the event', type: String, multi: true
        opt :timeout, 'Timeout (in seconds) when waiting for acknowledgements', default: 30
        opt :tcp, 'Use TCP transport instead of UDP (improves reliability, slight overhead.', default: true
        opt :tls, 'Use TLS for securing traffic', default: false
        opt :tls_key, 'TLS Key to use when using TLS', type: String
        opt :tls_cert, 'TLS Certificate to use when using TLS', type: String
        opt :tls_ca_cert, 'Trusted CA Certificate when using TLS', type: String
        opt :tls_verify, 'Verify TLS peer when using TLS', default: true
      end
    end

    attr_reader :argv

    def initialize(allow_arguments: false)
      options
      @argv = ARGV.dup
      abort "Error: stray arguments: #{ARGV.map(&:inspect).join(', ')}" if ARGV.any? && !allow_arguments

      options[:ttl] ||= options[:interval] * 2
      options[:ttl] = [options[:minimum_ttl], options[:ttl]].compact.max
    end

    # Returns parsed options (cached) from command line.
    def options
      @options ||= self.class.options
    end
    alias opts options

    def attributes
      @attributes ||= options[:attribute].to_h do |attr|
        k, v = attr.split('=')
        [k, v] if k && v
      end
    end

    def report(event)
      event[:tags] = event.fetch(:tags, []) + options[:tag]

      event[:ttl] ||= options[:ttl]

      event[:host] = options[:event_host].dup if options[:event_host]

      event = event.merge(attributes)

      riemann << event
    end

    def riemann
      @riemann ||= RiemannClientWrapper.new(options)
    end
    alias r riemann

    def run
      t0 = Time.now
      loop do
        begin
          tick
        rescue StandardError => e
          warn "#{e.class} #{e}\n#{e.backtrace.join "\n"}"
        end

        # Sleep.
        sleep(options[:interval] - ((Time.now - t0) % options[:interval]))
      end
    end

    def tick; end

    def endpoint_name(address, port)
      if address.ipv6?
        "[#{address}]:#{port}"
      else
        "#{address}:#{port}"
      end
    end
  end
end
