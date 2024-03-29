# frozen_string_literal: true

require 'riemann/tools'

# Gathers memcached STATS and submits them to Riemann.
module Riemann
  module Tools
    class Memcached
      include Riemann::Tools
      require 'socket'

      opt :memcached_host, 'Memcached hostname', default: 'localhost'
      opt :memcached_port, 'Memcached port', default: 11_211

      def tick
        sock = TCPSocket.new(opts[:memcached_host], opts[:memcached_port])
        sock.print("stats\r\n")
        sock.flush
        stats = sock.gets

        loop do
          stats = sock.gets
          break if stats.strip == 'END'

          m = stats.match(/STAT (\w+) (\S+)/)
          report(
            host: opts[:memcached_host].dup,
            service: "memcached #{m[1]}",
            metric: m[2].to_f,
            state: 'ok',
            tags: ['memcached'],
          )
        end
        sock.close
      end
    end
  end
end
