# frozen_string_literal: true

require 'riemann/tools'

# Gathers network interface statistics and submits them to Riemann.
module Riemann
  module Tools
    class Net
      include Riemann::Tools

      opt :interfaces, 'Interfaces to monitor', type: :strings, default: nil
      opt :ignore_interfaces, 'Interfaces to ignore', type: :strings, default: ['\Alo\d*\z']

      def initialize
        @old_state = nil
        @interfaces = if opts[:interfaces]
                        opts[:interfaces].reject(&:empty?).map(&:dup)
                      else
                        []
                      end
        @ignore_interfaces = opts[:ignore_interfaces].reject(&:empty?).map(&:dup)

        ostype = `uname -s`.chomp.downcase
        case ostype
        when 'freebsd'
          @state = method :freebsd_state
        else
          puts "WARNING: OS '#{ostype}' not explicitly supported. Falling back to Linux" unless ostype == 'linux'
          @state = method :linux_state
        end
      end

      def report_interface?(iface)
        if !@interfaces.empty?
          @interfaces.any? { |pattern| iface.match?(pattern) }
        else
          @ignore_interfaces.none? { |pattern| iface.match?(pattern) }
        end
      end

      FREEBSD_MAPPING = {
        'collisions'       => 'tx colls',
        'dropped-packets'  => 'rx drop',
        'received-bytes'   => 'rx bytes',
        'received-packets' => 'rx packets',
        'received-errors'  => 'rx errs',
        'sent-bytes'       => 'tx bytes',
        'sent-packets'     => 'tx packets',
        'send-errors'      => 'tx errs',
      }.freeze

      def freebsd_state
        require 'json'

        state = {}

        all_stats = JSON.parse(`netstat -inb --libxo=json`)
        all_stats.dig('statistics', 'interface').select { |s| s['mtu'] }.each do |interface_stats|
          next unless report_interface?(interface_stats['name'])

          FREEBSD_MAPPING.each do |key, service|
            state["#{interface_stats['name']} #{service}"] = interface_stats[key]
          end
        end

        state
      end

      def linux_state
        f = File.read('/proc/net/dev')
        state = {}
        f.split("\n").each do |line|
          next unless line =~ /\A\s*([[:alnum:]-]+?):\s*([\s\d]+)\s*/

          iface = Regexp.last_match(1)

          next unless report_interface?(iface)

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
           'tx drop',
           'tx fifo',
           'tx colls',
           'tx carrier',
           'tx compressed',].map do |service|
            "#{iface} #{service}"
          end.zip( # rubocop:disable Style/MultilineBlockChain
            Regexp.last_match(2).split(/\s+/).map(&:to_i),
          ).each do |service, value|
            state[service] = value
          end
        end

        state
      end

      def tick
        state = @state.call

        if @old_state
          # Report services from `@old_state` that don't exist in `state` as expired
          @old_state.reject { |k| state.key?(k) }.each_key do |service|
            report(service: service.dup, state: 'expired')
          end

          # Report delta for services that have values in both `@old_state` and `state`
          state.each do |service, metric|
            next unless @old_state.key?(service)

            delta = metric - @old_state[service]
            svc_state = case service
                        when /drop$/, /errs$/
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
              state: svc_state,
            )
          end
        end

        @old_state = state
      end
    end
  end
end
