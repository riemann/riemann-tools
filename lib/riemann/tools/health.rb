# frozen_string_literal: true

require 'riemann/tools'
require 'riemann/tools/utils'

module Riemann
  module Tools
    class Health
      include Riemann::Tools
      include Riemann::Tools::Utils

      opt :cpu_warning, 'CPU warning threshold (fraction of total jiffies)', default: 0.9
      opt :cpu_critical, 'CPU critical threshold (fraction of total jiffies)', default: 0.95
      opt :disk_warning, 'Disk warning threshold (fraction of space used)', default: 0.9
      opt :disk_critical, 'Disk critical threshold (fraction of space used)', default: 0.95
      opt :disk_ignorefs, 'A list of filesystem types to ignore',
          default: %w[anon_inodefs autofs cd9660 devfs devtmpfs fdescfs iso9660 linprocfs linsysfs nfs procfs]
      opt :load_warning, 'Load warning threshold (load average / core)', default: 3.0
      opt :load_critical, 'Load critical threshold (load average / core)', default: 8.0
      opt :memory_warning, 'Memory warning threshold (fraction of RAM)', default: 0.85
      opt :memory_critical, 'Memory critical threshold (fraction of RAM)', default: 0.95
      opt :checks, 'A list of checks to run.', type: :strings, default: %w[cpu load memory disk]

      def initialize
        @limits = {
          cpu: { critical: opts[:cpu_critical], warning: opts[:cpu_warning] },
          disk: { critical: opts[:disk_critical], warning: opts[:disk_warning] },
          load: { critical: opts[:load_critical], warning: opts[:load_warning] },
          memory: { critical: opts[:memory_critical], warning: opts[:memory_warning] }
        }
        case (@ostype = `uname -s`.chomp.downcase)
        when 'darwin'
          @cores = `sysctl -n hw.ncpu`.to_i
          @cpu = method :darwin_cpu
          @disk = method :disk
          @load = method :darwin_load
          @memory = method :darwin_memory
          darwin_top
        when 'freebsd'
          @cores = `sysctl -n hw.ncpu`.to_i
          @cpu = method :freebsd_cpu
          @disk = method :disk
          @load = method :bsd_load
          @memory = method :freebsd_memory
        when 'openbsd'
          @cores = `sysctl -n hw.ncpu`.to_i
          @cpu = method :openbsd_cpu
          @disk = method :disk
          @load = method :bsd_load
          @memory = method :openbsd_memory
        when 'sunos'
          @cores = `mpstat -a 2>/dev/null`.split[33].to_i
          @cpu = method :sunos_cpu
          @disk = method :disk
          @load = method :bsd_load
          @memory = method :sunos_memory
        else
          @cores = `nproc`.to_i
          puts "WARNING: OS '#{@ostype}' not explicitly supported. Falling back to Linux" unless @ostype == 'linux'
          @cpu = method :linux_cpu
          @disk = method :disk
          @load = method :linux_load
          @memory = method :linux_memory
          @supports_exclude_type = `df --help 2>&1 | grep -e "--exclude-type"` != ''
        end

        opts[:checks].each do |check|
          case check
          when 'disk'
            @disk_enabled = true
          when 'load'
            @load_enabled = true
          when 'cpu'
            @cpu_enabled = true
          when 'memory'
            @memory_enabled = true
          end
        end
      end

      def alert(service, state, metric, description)
        report(
          service: service.to_s,
          state: state.to_s,
          metric: metric.to_f,
          description: description
        )
      end

      def report_pct(service, fraction, report)
        if fraction
          if fraction > @limits[service][:critical]
            alert service, :critical, fraction, "#{format('%.2f', fraction * 100)}% #{report}"
          elsif fraction > @limits[service][:warning]
            alert service, :warning, fraction, "#{format('%.2f', fraction * 100)}% #{report}"
          else
            alert service, :ok, fraction, "#{format('%.2f', fraction * 100)}% #{report}"
          end
        end
      end

      def linux_cpu
        new = File.read('/proc/stat')
        unless new[/cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/]
          alert 'cpu', :unknown, nil, "/proc/stat doesn't include a CPU line"
          return false
        end
        u2, n2, s2, i2 = [Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3),
                          Regexp.last_match(4)].map(&:to_i)

        if @old_cpu
          u1, n1, s1, i1 = @old_cpu

          used = (u2 + n2 + s2) - (u1 + n1 + s1)
          total = used + i2 - i1
          fraction = used.to_f / total

          report_pct :cpu, fraction, "user+nice+system\n\n#{reverse_numeric_sort_with_header(`ps -eo pcpu,pid,comm`)}"
        end

        @old_cpu = [u2, n2, s2, i2]
      end

      def linux_load
        load = File.read('/proc/loadavg').split(/\s+/)[0].to_f / @cores
        if load > @limits[:load][:critical]
          alert 'load', :critical, load, "1-minute load average/core is #{load}"
        elsif load > @limits[:load][:warning]
          alert 'load', :warning, load, "1-minute load average/core is #{load}"
        else
          alert 'load', :ok, load, "1-minute load average/core is #{load}"
        end
      end

      def linux_memory
        m = File.read('/proc/meminfo').split(/\n/).each_with_object({}) do |line, info|
          x = line.split(/:?\s+/)
          # Assume kB...
          info[x[0]] = x[1].to_i
        end

        free = m['MemFree'].to_i + m['Buffers'].to_i + m['Cached'].to_i
        total = m['MemTotal'].to_i
        fraction = 1 - (free.to_f / total)

        report_pct :memory, fraction, "used\n\n#{reverse_numeric_sort_with_header(`ps -eo pmem,pid,comm`)}"
      end

      def freebsd_cpu
        u2, n2, s2, t2, i2 = `sysctl -n kern.cp_time 2>/dev/null`.split.map(&:to_i) # FreeBSD has 5 cpu stats

        if @old_cpu
          u1, n1, s1, t1, i1 = @old_cpu

          used = (u2 + n2 + s2 + t2) - (u1 + n1 + s1 + t1)
          total = used + i2 - i1
          fraction = used.to_f / total

          report_pct :cpu, fraction,
                     "user+nice+sytem+interrupt\n\n#{reverse_numeric_sort_with_header(`ps -axo pcpu,pid,comm`)}"
        end

        @old_cpu = [u2, n2, s2, t2, i2]
      end

      def openbsd_cpu
        u2, n2, s2, t2, i2 = # OpenBSD separates with ,
          `sysctl -n kern.cp_time 2>/dev/null`.split(',').map(&:to_i)
        if @old_cpu
          u1, n1, s1, t1, i1 = @old_cpu

          used = (u2 + n2 + s2 + t2) - (u1 + n1 + s1 + t1)
          total = used + i2 - i1
          fraction = used.to_f / total

          report_pct :cpu, fraction,
                     "user+nice+sytem+interrupt\n\n#{reverse_numeric_sort_with_header(`ps -axo pcpu,pid,comm`)}"
        end

        @old_cpu = [u2, n2, s2, t2, i2]
      end

      def sunos_cpu
        mpstats = `mpstat -a 2>/dev/null`.split
        u2 = mpstats[29].to_i
        s2 = mpstats[30].to_i
        t2 = mpstats[31].to_i
        i2 = mpstats[32].to_i

        if @old_cpu
          u1, s1, t1, i1 = @old_cpu

          used = (u2 + s2 + t2) - (u1 + s1 + t1)
          total = used + i2 - i1
          fraction = if i2 == i1 && used.zero? # If the system is <1% used in both samples then total will be 0 + (99 - 99), avoid a div by 0
                       0
                     else
                       used.to_f / total
                     end

          report_pct :cpu, fraction,
                     "user+sytem+interrupt\n\n#{reverse_numeric_sort_with_header(`ps -ao pcpu,pid,comm`)}"
        end

        @old_cpu = [u2, s2, t2, i2]
      end

      def bsd_load
        m = `uptime`.split(':')[-1].chomp.gsub(/\s+/, '').split(',')
        load = m[0].to_f / @cores
        if load > @limits[:load][:critical]
          alert 'load', :critical, load, "1-minute load average/core is #{load}"
        elsif load > @limits[:load][:warning]
          alert 'load', :warning, load, "1-minute load average/core is #{load}"
        else
          alert 'load', :ok, load, "1-minute load average/core is #{load}"
        end
      end

      def freebsd_memory
        meminfo = `sysctl -n vm.stats.vm.v_page_count vm.stats.vm.v_wire_count vm.stats.vm.v_active_count 2>/dev/null`.chomp.split
        fraction = (meminfo[1].to_f + meminfo[2].to_f) / meminfo[0].to_f

        report_pct :memory, fraction, "used\n\n#{reverse_numeric_sort_with_header(`ps -axo pmem,pid,comm`)}"
      end

      def openbsd_memory
        meminfo = `vmstat 2>/dev/null`.chomp.split
        fraction = meminfo[28].to_f / meminfo[29] # The ratio of active to free memory unlike the others :(

        report_pct :memory, fraction, "used\n\n#{reverse_numeric_sort_with_header(`ps -axo pmem,pid,comm`)}"
      end

      def sunos_memory
        meminfo = `vmstat 2>/dev/null`.chomp.split
        total_mem = `prtconf | grep Memory`.split[2].to_f * 1024 # reports in GB but vmstat is in MB
        fraction = (total_mem - meminfo[32].to_f) / total_mem

        report_pct :memory, fraction, "used\n\n#{reverse_numeric_sort_with_header(`ps -ao pmem,pid,comm`)}"
      end

      def darwin_top
        raw = `top -l 1 | grep -i "^\\(cpu\\|physmem\\|load\\)"`.chomp
        @topdata = { stamp: Time.now.to_i }
        raw.each_line do |ln|
          if ln.match(/Load Avg: [0-9.]+, [0-9.]+, ([0-9.])+/i)
            @topdata[:load] = Regexp.last_match(1).to_f
          elsif ln.match(/CPU usage: [0-9.]+% user, [0-9.]+% sys, ([0-9.]+)% idle/i)
            @topdata[:cpu] = 1 - (Regexp.last_match(1).to_f / 100)
          elsif mdat = ln.match(/PhysMem: ([0-9]+)([BKMGT]) wired, ([0-9]+)([BKMGT]) active, ([0-9]+)([BKMGT]) inactive, ([0-9]+)([BKMGT]) used, ([0-9]+)([BKMGT]) free/i)
            wired = mdat[1].to_i * (1024**'BKMGT'.index(mdat[2]))
            active = mdat[3].to_i * (1024**'BKMGT'.index(mdat[4]))
            inactive = mdat[5].to_i * (1024**'BKMGT'.index(mdat[6]))
            used = mdat[7].to_i * (1024**'BKMGT'.index(mdat[8]))
            free = mdat[9].to_i * (1024**'BKMGT'.index(mdat[10]))
            @topdata[:memory] = (wired + active + used).to_f / (wired + active + used + inactive + free)
          # This is for OSX Mavericks which
          # uses a different format for top
          # Example: PhysMem: 4662M used (1328M wired), 2782M unused.
          elsif mdat = ln.match(/PhysMem: ([0-9]+)([BKMGT]) used \(([0-9]+)([BKMGT]) wired\), ([0-9]+)([BKMGT]) unused/i)
            used  = mdat[1].to_i * (1024**'BKMGT'.index(mdat[2]))
            wired = mdat[3].to_i * (1024**'BKMGT'.index(mdat[4]))
            unused = mdat[5].to_i * (1024**'BKMGT'.index(mdat[6]))
            @topdata[:memory] = used.to_f / (used + unused)
          end
        end
      end

      def darwin_cpu
        darwin_top unless (Time.now.to_i - @topdata[:stamp]) < opts[:interval]
        unless @topdata[:cpu]
          alert 'cpu', :unknown, nil, 'unable to get CPU stats from top'
          return false
        end
        report_pct :cpu,  @topdata[:cpu], "usage\n\n#{reverse_numeric_sort_with_header(`ps -eo pcpu,pid,comm`)}"
      end

      def darwin_load
        darwin_top unless (Time.now.to_i - @topdata[:stamp]) < opts[:interval]
        unless @topdata[:load]
          alert 'load', :unknown, nil, 'unable to get load ave from top'
          return false
        end
        metric = @topdata[:load] / @cores
        if metric > @limits[:load][:critical]
          alert 'load', :critical, metric, "1-minute load average per core is #{metric}"
        elsif metric > @limits[:load][:warning]
          alert 'load', :warning, metric, "1-minute load average per core is #{metric}"
        else
          alert 'load', :ok, metric, "1-minute load average per core is #{metric}"
        end
      end

      def darwin_memory
        darwin_top unless (Time.now.to_i - @topdata[:stamp]) < opts[:interval]
        unless @topdata[:memory]
          alert 'memory', :unknown, nil, 'unable to get memory data from top'
          return false
        end
        report_pct :memory, @topdata[:memory], "usage\n\n#{reverse_numeric_sort_with_header(`ps -eo pmem,pid,comm`)}"
      end

      def df
        case @ostype
        when 'darwin', 'freebsd', 'openbsd'
          `df -P -t no#{opts[:disk_ignorefs].join(',')}`
        when 'sunos'
          `df -P` # Is there a good way to exlude iso9660 here?
        else
          if @supports_exclude_type
            `df -P #{opts[:disk_ignorefs].map { |fstype| "--exclude-type=#{fstype}" }.join(' ')}`
          else
            `df -P`
          end
        end
      end

      def disk
        df.split(/\n/).each do |r|
          f = r.split(/\s+/)
          next if f[0] == 'Filesystem'

          # Calculate capacity
          x = f[4].to_f / 100

          if x > @limits[:disk][:critical]
            alert "disk #{f[5]}", :critical, x, "#{f[4]} used"
          elsif x > @limits[:disk][:warning]
            alert "disk #{f[5]}", :warning, x, "#{f[4]} used"
          else
            alert "disk #{f[5]}", :ok, x, "#{f[4]} used"
          end
        end
      end

      def tick
        @cpu.call if @cpu_enabled
        @memory.call if @memory_enabled
        @disk.call if @disk_enabled
        @load.call if @load_enabled
      end
    end
  end
end
