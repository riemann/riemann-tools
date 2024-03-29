# frozen_string_literal: true

require 'open3'

require 'riemann/tools'

module Riemann
  module Tools
    class Zpool
      include Riemann::Tools

      def tick
        output, status = Open3.capture2e('zpool status -x')

        state = if status.success?
                  case output
                  when "all pools are healthy\n" then 'ok'
                  when /state: (DEGRADED|FAULTED)/ then 'critical'
                  else
                    'warning'
                  end
                else
                  'critical'
                end

        report(
          service: 'zpool health',
          description: output,
          state: state,
        )
      rescue Errno::ENOENT => e
        report(
          service: 'zpool health',
          description: e.message,
          state: 'critical',
        )
      end
    end
  end
end
