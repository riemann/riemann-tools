# frozen_string_literal: true

require 'riemann/tools'

# Gathers haproxy CSV statistics and submits them to Riemann.
module Riemann
  module Tools
    class Haproxy
      include Riemann::Tools
      require 'net/http'
      require 'csv'

      opt :stats_url, 'Full url to haproxy stats (eg: https://user:password@host.com:9999/stats)', required: true,
                                                                                                   type: :string

      def initialize
        @uri = URI("#{opts[:stats_url]};csv")
      end

      def tick
        csv.each do |row|
          row = row.to_hash
          ns  = "haproxy #{row['pxname']} #{row['svname']}"
          row.each do |property, metric|
            next if property.nil? || property == 'pxname' || property == 'svname'

            report(
              host: @uri.host,
              service: "#{ns} #{property}",
              metric: metric.to_f,
              tags: ['haproxy'],
            )
          end

          report(
            host: @uri.host,
            service: "#{ns} state",
            state: (%w[UP OPEN].include?(row['status']) ? 'ok' : 'critical'),
            tags: ['haproxy'],
          )
        end
      end

      def csv
        http = ::Net::HTTP.new(@uri.host, @uri.port)
        http.use_ssl = true if @uri.scheme == 'https'
        http.start do |h|
          get = ::Net::HTTP::Get.new(@uri.request_uri)
          unless @uri.userinfo.nil?
            userinfo = @uri.userinfo.split(':')
            get.basic_auth userinfo[0], userinfo[1]
          end
          h.request get
        end
        CSV.parse(http.body.split('# ')[1], { headers: true })
      end
    end
  end
end
