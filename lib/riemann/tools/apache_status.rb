# frozen_string_literal: true

require 'riemann/tools'
require 'riemann/tools/version'

# Collects Apache metrics and submits them to Riemann
# More information can be found at http://httpd.apache.org/docs/2.4/mod/mod_status.html

# Removes whitespace from 'Total Accesses' and 'Total kBytes' for output to graphite
module Riemann
  module Tools
    class ApacheStatus
      include Riemann::Tools
      require 'net/http'
      require 'uri'

      opt :uri, 'Apache Server Status URI', default: 'http://localhost/server-status'
      opt :user_agent, 'User-Agent header for HTTP requests', short: :none, default: "#{File.basename($PROGRAM_NAME)}/#{Riemann::Tools::VERSION} (+https://github.com/riemann/riemann-tools)"

      def initialize
        @uri = URI.parse("#{opts[:uri]}?auto")
        # Sample Response with ExtendedStatus On
        # Total Accesses: 20643
        # Total kBytes: 36831
        # CPULoad: .0180314
        # Uptime: 43868
        # ReqPerSec: .470571
        # BytesPerSec: 859.737
        # BytesPerReq: 1827.01
        # BusyWorkers: 6
        # IdleWorkers: 94
        # Scoreboard: ___K_____K____________W_

        @scoreboard_map = {
          '_' => 'waiting',
          'S' => 'starting',
          'R' => 'reading',
          'W' => 'sending',
          'K' => 'keepalive',
          'D' => 'dns',
          'C' => 'closing',
          'L' => 'logging',
          'G' => 'graceful',
          'I' => 'idle',
          '.' => 'open',
        }
      end

      def get_scoreboard_metrics(response)
        results = Hash.new(0)

        response.slice! 'Scoreboard: '
        response.each_char do |char|
          results[char] += 1
        end
        results.transform_keys { |k| @scoreboard_map[k] }
      end

      def report_metrics(metrics)
        metrics.each do |k, v|
          report(
            service: "httpd #{k}",
            metric: v.to_f,
            state: 'ok',
            tags: ['httpd'],
          )
        end
      end

      def connection
        response = nil
        begin
          response = ::Net::HTTP.new(@uri.host, @uri.port).get(@uri, { 'user-agent' => opts[:user_agent] }).body
        rescue StandardError => e
          report(
            service: 'httpd health',
            state: 'critical',
            description: "Httpd connection error: #{e.class} - #{e.message}",
            tags: ['httpd'],
          )
        else
          report(
            service: 'httpd health',
            state: 'ok',
            description: 'Httpd connection status ok',
            tags: ['httpd'],
          )
        end
        response
      end

      def tick
        return if (response = connection).nil?

        response.each_line do |line|
          metrics = {}

          if line =~ /Scoreboard/
            metrics = get_scoreboard_metrics(line.strip)
          else
            key, value = line.strip.split(':')
            metrics[key.gsub(/\s/, '')] = value
          end
          report_metrics(metrics)
        end
      end
    end
  end
end
