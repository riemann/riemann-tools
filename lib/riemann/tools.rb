# frozen_string_literal: true

module Riemann
  module Tools
    require 'optimist'
    require 'riemann/client'

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
        opt :ttl, 'TTL for events', type: Integer
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

    # Returns parsed options (cached) from command line.
    def options
      @options ||= self.class.options
    end
    alias opts options

    def attributes
      @attributes ||= Hash[options[:attribute].map do |attr|
        k, v = attr.split(/=/)
        [k, v] if k && v
      end]
    end

    def report(event)
      if options[:tag]
        # Work around a bug with beefcake which can't take frozen strings.
        event[:tags] = [*event.fetch(:tags, [])] + options[:tag].map(&:dup)
      end

      event[:ttl] ||= (options[:ttl] || (options[:interval] * 2))

      event[:host] = options[:event_host].dup if options[:event_host]

      event = event.merge(attributes)

      riemann << event
    end

    def new_riemann_client
      r = Riemann::Client.new(
        host: options[:host],
        port: options[:port],
        timeout: options[:timeout],
        ssl: options[:tls],
        key_file: options[:tls_key],
        cert_file: options[:tls_cert],
        ca_file: options[:tls_ca_cert],
        ssl_verify: options[:tls_verify]
      )
      if options[:tcp] || options[:tls]
        r.tcp
      else
        r
      end
    end

    def riemann
      @riemann ||= new_riemann_client
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
  end
end
