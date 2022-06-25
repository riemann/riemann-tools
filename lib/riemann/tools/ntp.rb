# frozen_string_literal: true

require 'riemann/tools'

module Riemann
  module Tools
    class Ntp
      include Riemann::Tools

      def initialize
        @hostname = `hostname`.chomp
        @ostype = `uname -s`.chomp.downcase
        abort 'WARNING: macOS not explicitly supported. Exiting.' if @ostype == 'darwin'
      end

      def tick
        stats = `ntpq -p -n`
        stats.each_line do |stat|
          m = stat.split
          next if m.grep(/^===/).any? || m.grep(/^remote/).any?

          @ntp_host = m[0].gsub('*', '').gsub('-', '').gsub('+', '')
          send('delay', m[7])
          send('offset', m[8])
          send('jitter', m[9])
        end
      end

      def send(type, metric)
        report(
          host: @hostname,
          service: "ntp peer #{@ntp_host} #{type}",
          metric: metric.to_f,
          state: 'ok',
          description: "ntp peer #{@ntp_host} #{type}",
          tags: ['ntp'],
        )
      end
    end
  end
end
