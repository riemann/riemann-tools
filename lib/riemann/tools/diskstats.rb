# frozen_string_literal: true

require 'riemann/tools'

module Riemann
  module Tools
    class Diskstats
      include Riemann::Tools

      opt :devices, 'Devices to monitor', type: :strings, default: nil
      opt :ignore_devices, 'Devices to ignore', type: :strings, default: nil

      def initialize
        @old_state = nil
      end

      def state
        f = File.read('/proc/diskstats')
        state = f.split("\n").reject { |d| d =~ /(ram|loop)/ }.each_with_object({}) do |line, s|
          next unless line =~ /^(?:\s+\d+){2}\s+([\w\d-]+) (.*)$/

          dev = Regexp.last_match(1)

          ['reads reqs',
           'reads merged',
           'reads sector',
           'reads time',
           'writes reqs',
           'writes merged',
           'writes sector',
           'writes time',
           'io reqs',
           'io time',
           'io weighted',].map do |service|
            "#{dev} #{service}"
          end.zip( # rubocop:disable Style/MultilineBlockChain
            Regexp.last_match(2).split(/\s+/).map(&:to_i),
          ).each do |service, value|
            s[service] = value
          end
        end

        # Filter interfaces
        if (is = opts[:devices])
          state = state.select do |service, _value|
            is.include? service.split.first
          end
        end

        if (ign = opts[:ignore_devices])
          state = state.reject do |service, _value|
            ign.include? service.split.first
          end
        end

        state
      end

      def tick
        state = self.state

        if @old_state
          state.each do |service, metric|
            if service =~ /io reqs$/
              report(
                service: "diskstats #{service}",
                metric: metric,
                state: 'ok',
              )
            else
              delta = metric - @old_state[service]

              report(
                service: "diskstats #{service}",
                metric: (delta.to_f / opts[:interval]),
                state: 'ok',
              )
            end

            next unless service =~ /io time$/

            report(
              service: "diskstats #{service.gsub('time', 'util')}",
              metric: (delta.to_f / (opts[:interval] * 1000)),
              state: 'ok',
            )
          end
        end

        @old_state = state
      end
    end
  end
end
