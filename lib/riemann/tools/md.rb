# frozen_string_literal: true

require 'riemann/tools'
require 'riemann/tools/mdstat_parser.tab'

module Riemann
  module Tools
    class Md
      include Riemann::Tools

      def mdstat_parser
        @mdstat_parser ||= MdstatParser.new
      end

      def tick
        status = File.read('/proc/mdstat')
        res = mdstat_parser.parse(status)

        state = res.values.all? { |value| value =~ /\AU+\z/ } ? 'ok' : 'critical'

        report(
          service: 'mdstat',
          description: status,
          state: state,
        )
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
    end
  end
end
