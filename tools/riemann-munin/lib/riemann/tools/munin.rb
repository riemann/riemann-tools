# frozen_string_literal: true

require 'riemann/tools'

# Gathers munin statistics and submits them to Riemann.
module Riemann
  module Tools
    class Munin
      include Riemann::Tools
      require 'munin-ruby'

      def initialize
        @munin = ::Munin::Node.new
      end

      def tick
        services = opts[:services] || @munin.list
        services.each do |service_name|
          @munin.fetch(service_name).each do |service, parts|
            parts.each do |part, metric|
              report(
                service: "#{service} #{part}",
                metric: metric.to_f,
                state: 'ok',
                tags: ['munin'],
              )
            end
          end
        end
      end

      opt :munin_host, 'Munin hostname', default: 'localhost'
      opt :munin_port, 'Munin port', default: 4949
      opt :services, 'Munin services to translate (if not specified, all services are relayed)', type: :strings
    end
  end
end
