# frozen_string_literal: true

require 'riemann/tools'

# Checks for open tcp ports.
# (c) Max Voit 2017
module Riemann
  module Tools
    class Portcheck
      include Riemann::Tools

      require 'socket'

      opt :hostname, 'Host, defaults to localhost', default: `hostname`.chomp
      opt :ports, "List of ports to check, e.g. '-r 80 443'", type: :ints

      def initialize
        super

        @hostname = opts.fetch(:hostname)
        @ports = opts.fetch(:ports)
      end

      def tick
        @ports.each do |thisport|
          # try opening tcp connection with 5s timeout;
          # if this fails, the port is considered closed
          portopen = begin
            Socket.tcp(@hostname, thisport, connect_timeout: 5) { true }
          rescue StandardError
            false
          end
          state = if portopen
                    'ok'
                  else
                    'critical'
                  end
          report(
            host: @hostname.to_s,
            service: "port #{thisport}",
            state: state.to_s,
            tags: ['portcheck'],
          )
        end
      end
    end
  end
end
