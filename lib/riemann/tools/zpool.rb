# frozen_string_literal: true

require 'open3'

require 'riemann/tools'

module Riemann
  module Tools
    class Zpool
      include Riemann::Tools

      def tick
        output, status = Open3.capture2e('zpool status -x')

        report(
          service: 'zpool health',
          message: output,
          state: status.success? ? 'ok' : 'critical',
        )
      rescue Errno::ENOENT => e
        report(
          service: 'zpool health',
          message: e.message,
          state: 'critical',
        )
      end
    end
  end
end
