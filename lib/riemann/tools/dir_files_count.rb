# frozen_string_literal: true

require 'riemann/tools'

# Gets the number of files present on a directory and submits it to riemann
module Riemann
  module Tools
    class DirFilesCount
      include Riemann::Tools

      opt :directory, '', default: '/var/log'
      opt :service_prefix, 'The first part of the service name, before the directory path', default: 'dir-files-count'
      opt :warning, 'Dir files number warning threshold', type: Integer
      opt :critical, 'Dir files number critical threshold', type: Integer
      opt :alert_on_missing, 'Send a critical metric if the directory is missing?', default: true

      def initialize
        super

        @dir = opts.fetch(:directory)
        @service_prefix = opts.fetch(:service_prefix)
        @warning = opts.fetch(:warning, nil)
        @critical = opts.fetch(:critical, nil)
        @alert_on_missing = opts.fetch(:alert_on_missing)
      end

      def tick
        if Dir.exist?(@dir)
          metric = Dir.entries(@dir).size - 2
          report(
            service: "#{@service_prefix} #{@dir}",
            metric: metric,
            state: state(metric),
            tags: ['dir_files_count'],
          )
        elsif @alert_on_missing
          report(
            service: "#{@service_prefix} #{@dir} missing",
            description: "#{@service_prefix} #{@dir} does not exist",
            metric: metric,
            state: 'critical',
            tags: ['dir_files_count'],
          )
        end
      end

      def state(metric)
        if @critical && metric > @critical
          'critical'
        elsif @warning && metric > @warning
          'warning'
        else
          'ok'
        end
      end
    end
  end
end
