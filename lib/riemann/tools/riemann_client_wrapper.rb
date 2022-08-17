# frozen_string_literal: true

require 'singleton'

require 'riemann/client'

module Riemann
  module Tools
    class RiemannClientWrapper
      include Singleton

      def initialize
        @client = nil
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
        self
      end

      def <<(event)
        @client << event
      end
    end
  end
end
