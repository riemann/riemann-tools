# frozen_string_literal: true

require 'English'
require 'riemann/tools'

module Riemann
  module Tools
    class Freeswitch
      include Riemann::Tools

      opt :calls_warning, 'Calls warning threshold', default: 100
      opt :calls_critical, 'Calls critical threshold', default: 300
      opt :pid_file, 'FreeSWITCH daemon pidfile', type: String, default: '/var/run/freeswitch/freeswitch.pid'

      def initialize
        super

        @limits = {
          calls: { critical: opts[:calls_critical], warning: opts[:calls_warning] },
        }
      end

      def dead_proc?(pid)
        Process.getpgid(pid)
        false
      rescue Errno::ESRCH
        true
      end

      def alert(service, state, metric, description)
        report(
          service: service.to_s,
          state: state.to_s,
          metric: metric.to_f,
          description: description,
        )
      end

      def exec_with_timeout(cmd, timeout)
        pid = Process.spawn(cmd, { %i[err out] => :close, :pgroup => true })
        begin
          Timeout.timeout(timeout) do
            Process.waitpid(pid, 0)
            $CHILD_STATUS.exitstatus.zero?
          end
        rescue Timeout::Error
          Process.kill(15, -Process.getpgid(pid))
          puts "Killed pid: #{pid}"
          false
        end
      end

      def tick
        # Determine how many current calls I have according to FreeSWITCH
        fs_calls = `fs_cli -x "show calls count"| grep -Po '^\\d+'`.to_i

        # Determine how many current channels I have according to FreeSWITCH
        fs_channels = `fs_cli -x "show channels count"| grep -Po '^\\d+'`.to_i

        # Determine how many conferences I have according to FreeSWITCH
        fs_conferences = `fs_cli -x "conference list"| grep -Pco '^Conference'`.to_i

        # Try to read pidfile. If it fails use Devil's dummy PID
        begin
          fs_pid = File.read(opts[:pid_file]).to_i
        rescue StandardError
          puts "Couldn't read pidfile: #{opts[:pid_file]}"
          fs_pid = -666
        end

        fs_threads = fs_pid.positive? ? `ps huH p #{fs_pid} | wc -l`.to_i : 0

        # Submit calls to riemann
        if fs_calls > @limits[:calls][:critical]
          alert 'FreeSWITCH current calls', :critical, fs_calls, "Number of calls are #{fs_calls}"
        elsif fs_calls > @limits[:calls][:warning]
          alert 'FreeSWITCH current calls', :warning, fs_calls, "Number of calls are #{fs_calls}"
        else
          alert 'FreeSWITCH current calls', :ok, fs_calls, "Number of calls are #{fs_calls}"
        end

        # Submit channels to riemann
        if fs_channels > @limits[:calls][:critical]
          alert 'FreeSWITCH current channels', :critical, fs_channels, "Number of channels are #{fs_channels}"
        elsif fs_channels > @limits[:calls][:warning]
          alert 'FreeSWITCH current channels', :warning, fs_channels, "Number of channels are #{fs_channels}"
        else
          alert 'FreeSWITCH current channels', :ok, fs_channels, "Number of channels are #{fs_channels}"
        end

        # Submit conferences to riemann
        if fs_conferences > @limits[:calls][:critical]
          alert 'FreeSWITCH current conferences', :critical, fs_conferences,
                "Number of conferences are #{fs_conferences}"
        elsif fs_conferences > @limits[:calls][:warning]
          alert 'FreeSWITCH current conferences', :warning, fs_conferences,
                "Number of conferences are #{fs_conferences}"
        else
          alert 'FreeSWITCH current conferences', :ok, fs_conferences, "Number of conferences are #{fs_conferences}"
        end

        # Submit threads to riemann
        alert 'FreeSWITCH current threads', :ok, fs_threads, "Number of threads are #{fs_threads}" if fs_threads

        # Submit status to riemann
        if dead_proc?(fs_pid)
          alert 'FreeSWITCH status', :critical, -1, 'FreeSWITCH service status: not running'
        else
          alert 'FreeSWITCH status', :ok, nil, 'FreeSWITCH service status: running'
        end

        # Submit CLI status to riemann using timeout in case it's unresponsive
        if exec_with_timeout('fs_cli -x status', 2)
          alert 'FreeSWITCH CLI status', :ok, nil, 'FreeSWITCH CLI status: responsive'
        else
          alert 'FreeSWITCH CLI status', :critical, -1, 'FreeSWITCH CLI status: not responding'
        end
      end
    end
  end
end
