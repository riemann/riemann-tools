# frozen_string_literal: true

require 'riemann/tools'

# Reports running process count to riemann.
module Riemann
  module Tools
    class Proc
      include Riemann::Tools

      opt :proc_regex, 'regular expression that matches the process to be monitored', type: :string, default: '.*'
      opt :proc_min_critical, 'running process count minimum', default: 0
      opt :proc_max_critical, 'running process count maximum', default: 65_536

      def initialize
        super

        @limits = { critical: { min: opts[:proc_min_critical], max: opts[:proc_max_critical] } }

        abort 'FATAL: specify a process regular expression, see --help for usage' unless opts[:proc_regex]

        ostype = `uname -s`.chomp.downcase
        puts "WARNING: OS '#{ostype}' not explicitly supported. Falling back to Linux" unless ostype == 'linux'
        @check = method :linux_proc
      end

      def alert(service, state, metric, description)
        report(
          service: service.to_s,
          state: state.to_s,
          metric: metric.to_f,
          description: description,
        )
      end

      def linux_proc
        process = opts[:proc_regex]
        found = `ps axo pid=,rss=,vsize=,state=,cputime=,lstart=,command= | grep '#{process}' | grep -v grep | grep -v riemann-proc`
        running = found.count("\n")
        if (running > @limits[:critical][:max]) || (running < @limits[:critical][:min])
          alert "proc count/#{process}", :critical, running, "process #{process} is running #{running} instances.\n"
        else
          alert "proc count/#{process}", :ok, running, "process #{process} is running #{running} instances.\n"
        end
        # Iterate on all the lines and create an entry for the following metrics:
        #
        # process/<pid>-<start-time>/rss
        # process/<pid>-<start-time>/vsize
        # process/<pid>-<start-time>/running
        # process/<pid>-<start-time>/cputime
        #
        # description should contain the command itself.
        # value should be either process RSS, VSIZE, or 1 if running
        # state is always unknown for the moment
        #
        ps_regex = /([0-9]+) +([0-9]+) +([0-9]+) +([A-Z]) +([0-9:.]+) +[A-Za-z]{3} +([A-Za-z]{3} {1,2}[0-9]+ [0-9:]+ [0-9]+) +(.*)/
        found.each_line do |line|
          m = ps_regex.match(line)
          next if m.nil?

          pid, rss, vsize, state, cputime, start, command = m.captures
          start_s = DateTime.parse(start, 'Mmm DD HH:MM:ss YYYY').to_time.to_i
          cputime_s = DateTime.parse(cputime, '%H:%M:%S')
          cputime_seconds = (cputime_s.hour * 3600) + (cputime_s.minute * 60) + cputime_s.second
          running = 0
          case state[0]
          when 'R'
            state_s = 'ok'
            running = 1
          when 'S'
            state_s = 'ok'
          when 'I'
            state_s = 'warning'
          when 'T', 'U', 'Z'
            state_s = 'critical'
          else
            state_s = 'unknown'
          end
          report(
            service: "proc #{pid}-#{start_s}/rss",
            state: state_s.to_s,
            metric: rss.to_f,
            description: command,
          )
          report(
            service: "proc #{pid}-#{start_s}/vsize",
            state: state_s.to_s,
            metric: vsize.to_f,
            description: command,
          )
          report(
            service: "proc #{pid}-#{start_s}/running",
            state: state_s.to_s,
            metric: running.to_f,
            description: command,
          )
          report(
            service: "proc #{pid}-#{start_s}/cputime",
            state: state_s.to_s,
            metric: cputime_seconds,
            description: command,
          )
        end
      end

      def tick
        @check.call
      end
    end
  end
end
