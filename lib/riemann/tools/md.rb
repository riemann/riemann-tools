# frozen_string_literal: true

require 'riemann/tools'
require 'riemann/tools/mdstat_parser.tab'

module Riemann
  module Tools
    class Md
      include Riemann::Tools

      opt :devices, 'Devices to monitor', type: :strings, default: []
      opt :ignore_devices, 'Devices to ignore', type: :strings, default: []

      def mdstat_parser
        @mdstat_parser ||= MdstatParser.new
      end

      def tick
        status = File.read('/proc/mdstat')
        res = mdstat_parser.parse(status)

        res.each do |device, member_status|
          next unless report_device?(device)

          report(
            service: "mdstat #{device}",
            description: member_status,
            state: member_status =~ /\AU+\z/ ? 'ok' : 'critical',
          )
        end
      rescue Racc::ParseError => e
        report(
          service: 'mdstat',
          description: "Error parsing mdstat: #{e.message}",
          state: 'critical',
        )
      rescue Errno::ENOENT => e
        report(
          service: 'mdstat',
          description: e.message,
          state: 'critical',
        )
      end

      def report_device?(device)
        if !opts[:devices].empty?
          opts[:devices].include?(device)
        else
          !opts[:ignore_devices].include?(device)
        end
      end
    end
  end
end
