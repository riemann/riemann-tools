# frozen_string_literal: true

require 'riemann/tools'

# Gathers zookeeper STATS and submits them to Riemann.
module Riemann
  module Tools
    class Zookeeper
      include Riemann::Tools
      require 'socket'

      opt :zookeeper_host, 'Zookeeper hostname', default: 'localhost'
      opt :zookeeper_port, 'Zookeeper port', default: 2181

      def tick
        sock = TCPSocket.new(opts[:zookeeper_host], opts[:zookeeper_port])
        sock.sync = true
        sock.print('mntr')
        sock.flush

        loop do
          stats = sock.gets

          break if stats.nil?

          m = stats.match(/^(\w+)\t+(.*)/)

          report(
            host: opts[:zookeeper_host].dup,
            service: "zookeeper #{m[1]}",
            metric: m[2].to_f,
            state: 'ok',
            tags: ['zookeeper'],
          )
        end
        sock.close
      end
    end
  end
end
