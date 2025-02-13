# frozen_string_literal: true

require 'riemann/tools'

# See https://www.kernel.org/doc/html/latest/hwmon/index.html
module Riemann
  module Tools
    class Hwmon
      include Riemann::Tools

      class Device
        attr_reader :hwmon, :type, :number, :crit, :lcrit, :service

        def initialize(hwmon, type, number)
          @hwmon = hwmon
          @type = type
          @number = number

          @crit = scale(read_hwmon_i('crit'))
          @lcrit = scale(read_hwmon_i('lcrit'))
          @service = ['hwmon', read_hwmon_file('name'), read_hwmon_s('label')].compact.join(' ')
        end

        def input
          read_hwmon_i('input')
        end

        def report
          value = scale(input)

          state = :ok
          state = :critical if crit && value >= crit
          state = :critical if lcrit && value <= lcrit
          {
            service: service,
            state: state,
            metric: value,
            description: fromat_input(value),
          }
        end

        private

        def scale(value)
          return nil if value.nil?

          case type
          when :fan then value.to_i # rpm
          when :in, :temp, :curr then value.to_f / 1000 # mV, m°C, mA
          when :humidity then value.to_f / 100 # %H
          when :power, :energy then value.to_f / 1_000_000 # uW, uJ
          end
        end

        def fromat_input(value)
          case type
          when :in then format('%<value>.3f V', { value: value })
          when :fan then "#{value} RPM"
          when :temp then format('%<value>.3f °C', { value: value })
          when :curr then format('%<value>.3f A', { value: value })
          when :power then format('%<value>.3f W', { value: value })
          when :energy then format('%<value>.3f J', { value: value })
          when :humidity then format('%<value>d %H', { value: (value * 100).to_i })
          end
        end

        def read_hwmon_i(file)
          s = read_hwmon_s(file)
          return nil if s.nil?

          s.to_i
        end

        def read_hwmon_s(file)
          read_hwmon_file("#{type}#{number}_#{file}")
        end

        def read_hwmon_file(file)
          File.read("/sys/class/hwmon/hwmon#{hwmon}/#{file}").chomp
        rescue Errno::ENOENT
          nil
        end
      end

      attr_reader :devices

      def initialize
        super

        @devices = poll_devices
      end

      def poll_devices
        res = []

        Dir['/sys/class/hwmon/hwmon[0-9]*/{in,fan,temp,curr,power,energy,humidity}[0-9]*_input'].each do |filename|
          m = filename.match(%r{/sys/class/hwmon/hwmon(\d+)/([[:alpha:]]+)(\d+)_input})
          res << Device.new(m[1].to_i, m[2].to_sym, m[3].to_i)
        end

        res
      end

      def tick
        devices.each do |device|
          report(device.report)
        rescue Errno::ENODATA
          # Some sensors are buggy and cannot report properly
        end
      end
    end
  end
end
