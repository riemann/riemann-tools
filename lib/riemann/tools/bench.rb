# frozen_string_literal: true

require 'riemann/tools'
require 'riemann/tools/version'

# Connects to a server (first arg) and populates it with a constant stream of
# events for testing.
module Riemann
  module Tools
    class Bench
      include Riemann::Tools
      attr_accessor :hosts, :services, :states

      def initialize
        super

        @hosts = [nil] + (0...10).map { |i| "host#{i}" }
        @hosts = %w[a b c d e f g h i j]
        @services = %w[test1 test2 test3 foo bar baz xyzzy attack cat treat]
        @states = {}
      end

      def evolve(state)
        m = state[:metric] + ((rand - 0.5) * 0.1)
        m = m.clamp(0, 1)

        s = case m
            when 0...0.75
              'ok'
            when 0.75...0.9
              'warning'
            when 0.9..1.0
              'critical'
            end

        {
          metric: m,
          state: s,
          host: state[:host],
          service: state[:service],
          description: "at #{Time.now}",
        }
      end

      def tick
        #    pp @states
        hosts.product(services).each do |id|
          report(states[id] = evolve(states[id]))
        end
      end

      def run
        start
        loop do
          sleep 0.05
          tick
        end
      end

      def start
        hosts.product(services).each do |host, service|
          states[[host, service]] = {
            metric: 0.5,
            state: 'ok',
            description: 'Starting up',
            host: host,
            service: service,
          }
        end
      end
    end
  end
end
