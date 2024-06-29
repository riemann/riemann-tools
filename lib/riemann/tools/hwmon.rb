# frozen_string_literal: true

require 'riemann/tools'

# See https://www.kernel.org/doc/html/latest/hwmon/index.html
module Riemann
  module Tools
    class Hwmon
      include Riemann::Tools

      class Device
        attr_reader :hwmon, :type, :number, :crit, :lcrit, :label, :name

        def initialize(hwmon, type, number)
          @hwmon = hwmon
          @type = type
          @number = number

          @crit = scale(read_hwmon_i('crit'))
          @lcrit = scale(read_hwmon_i('lcrit'))
          @label = read_hwmon_s('label')
          @name = read_hwmon_file('name')
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
            service: "hwmon #{name} #{label}",
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

      FIRST_NUMBER = {
        in: 0,
        fan: 1,
        temp: 1,
        curr: 1,
        power: 1,
        energy: 1,
        humidity: 1,
      }.freeze

      attr_reader :devices

      def initialize
        super

        @devices = poll_devices
      end

      def poll_devices
        res = []

        hwmon = 0
        while File.exist?("/sys/class/hwmon/hwmon#{hwmon}")
          %i[in fan temp curr power energy humidity].each do |type|
            number = FIRST_NUMBER[type]
            while File.exist?("/sys/class/hwmon/hwmon#{hwmon}/#{type}#{number}_input")
              res << Device.new(hwmon, type, number)

              number += 1
            end
          end

          hwmon += 1
        end

        res
      end

      def tick
        devices.each do |device|
          report(device.report)
        end
      end
    end
  end
end
