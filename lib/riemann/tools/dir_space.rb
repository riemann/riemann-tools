# frozen_string_literal: true

require 'riemann/tools'

# Gathers the space used by a directory and submits it to riemann
module Riemann
  module Tools
    class DirSpace
      include Riemann::Tools

      opt :directory, '', default: '/var/log'
      opt :service_prefix, 'The first part of the service name, before the directory path', default: 'dir-space'
      opt :warning, 'Dir space warning threshold (in bytes)', type: Integer
      opt :critical, 'Dir space critical threshold (in bytes)', type: Integer
      opt :alert_on_missing, 'Send a critical metric if the directory is missing?', default: true

      def initialize
        @dir = opts.fetch(:directory)
        @service_prefix = opts.fetch(:service_prefix)
        @warning = opts.fetch(:warning, nil)
        @critical = opts.fetch(:critical, nil)
        @alert_on_missing = opts.fetch(:alert_on_missing)
      end

      def tick
        if Dir.exist?(@dir)
          metric = `du '#{@dir}'`.lines.to_a.last.split("\t")[0].to_i
          report(
            service: "#{@service_prefix} #{@dir}",
            metric: metric,
            state: state(metric),
            tags: ['dir_space'],
          )
        elsif @alert_on_missing
          report(
            service: "#{@service_prefix} #{@dir} missing",
            description: "#{@service_prefix} #{@dir} does not exist",
            metric: metric,
            state: 'critical',
            tags: ['dir_space'],
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
