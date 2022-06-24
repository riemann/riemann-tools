# frozen_string_literal: true

require 'riemann/tools'

module Riemann
  module Tools
    class Net
      include Riemann::Tools

      opt :interfaces, 'Interfaces to monitor', type: :strings, default: nil
      opt :ignore_interfaces, 'Interfaces to ignore', type: :strings, default: ['lo']

      def initialize
        @old_state = nil
        @interfaces = if opts[:interfaces]
                        opts[:interfaces].reject(&:empty?).map(&:dup)
                      else
                        []
                      end
        @ignore_interfaces = opts[:ignore_interfaces].reject(&:empty?).map(&:dup)
      end

      def state
        f = File.read('/proc/net/dev')
        state = {}
        f.split("\n").each do |line|
          next unless line =~ /\A\s*([[:alnum:]-]+?):\s*([\s\d]+)\s*/

          iface = Regexp.last_match(1)

          next unless @interfaces.empty? || @interfaces.any? { |pattern| iface.match?(pattern) }
          next if @ignore_interfaces.any? { |pattern| iface.match?(pattern) }

          ['rx bytes',
           'rx packets',
           'rx errs',
           'rx drop',
           'rx fifo',
           'rx frame',
           'rx compressed',
           'rx multicast',
           'tx bytes',
           'tx packets',
           'tx errs',
           'tx drops',
           'tx fifo',
           'tx colls',
           'tx carrier',
           'tx compressed'].map do |service|
            "#{iface} #{service}"
          end.zip( # rubocop:disable Style/MultilineBlockChain
            Regexp.last_match(2).split(/\s+/).map(&:to_i)
          ).each do |service, value|
            state[service] = value
          end
        end

        state
      end

      def tick
        state = self.state

        if @old_state
          # Report services from `@old_state` that don't exist in `state` as expired
          @old_state.reject { |k| state.key?(k) }.each do |service, _metric|
            report(service: service.dup, state: 'expired')
          end

          # Report delta for services that have values in both `@old_state` and `state`
          state.each do |service, metric|
            next unless @old_state.key?(service)

            delta = metric - @old_state[service]
            svc_state = case service
                        when /drop$/
                          if delta.positive?
                            'warning'
                          else
                            'ok'
                          end
                        when /errs$/
                          if delta.positive?
                            'warning'
                          else
                            'ok'
                          end
                        else
                          'ok'
                        end

            report(
              service: service.dup,
              metric: (delta.to_f / opts[:interval]),
              state: svc_state
            )
          end
        end

        @old_state = state
      end
    end
  end
end
