# frozen_string_literal: true

require 'socket'

module Riemann
  module Tools
    module Utils # :nodoc:
      class StringTokenizer
        attr_reader :tokens

        def initialize(text)
          @scanner = StringScanner.new(text)

          @lineno = 1
          @pos = 0
          @line = next_line
          @tokens = []
        end

        def scan(expression)
          @scanner.scan(expression)
        end

        def eos?
          @scanner.eos?
        end

        def matched
          @scanner.matched
        end

        def next_line
          (@scanner.check_until(/\n/) || @scanner.rest).chomp
        end

        def push_token(token, value = nil)
          value ||= @scanner.matched

          if value == "\n"
            @lineno += 1
            @line = next_line
            @pos = pos = 0
          else
            pos = @pos
            @pos += @scanner.matched.length
          end

          @tokens << [token, { value: value, line: @line, lineno: @lineno, pos: pos }] if token
        end

        def unexpected_token
          raise(Racc::ParseError, "unexpected data on line #{@lineno}:\n#{@line}\n#{' ' * @pos}^")
        end
      end

      def reverse_numeric_sort_with_header(data, header: 1, count: 10)
        lines = data.chomp.split("\n")
        header = lines.shift(header)

        lines.sort_by!(&:to_f)
        lines.reverse!

        (header + lines[0, count]).join("\n")
      end

      def when_from_now(date)
        if date > now
          "in #{distance_of_time_in_words_to_now(date)}"
        else
          "#{distance_of_time_in_words_to_now(date)} ago"
        end
      end

      # Stolen from ActionView, to avoid pulling a lot of dependencies
      def distance_of_time_in_words_to_now(to_time)
        distance_in_seconds = (to_time - now).round.abs
        distance_in_minutes = distance_in_seconds / 60

        case distance_in_minutes
        when 0                then 'less than 1 minute'
        when 1...45           then pluralize_string('%d minute', distance_in_minutes)
        when 45...1440        then pluralize_string('about %d hour', (distance_in_minutes.to_f / 60.0).round)
          # 24 hours up to 30 days
        when 1440...43_200    then pluralize_string('%d day', (distance_in_minutes.to_f / 1440.0).round)
          # 30 days up to 60 days
        when 43_200...86_400  then pluralize_string('about %d month', (distance_in_minutes.to_f / 43_200.0).round)
          # 60 days up to 365 days
        when 86_400...525_600 then pluralize_string('%d month', (distance_in_minutes.to_f / 43_200.0).round)
        else
          pluralize_string('about %d year', (distance_in_minutes.to_f / 525_600.0).round)
        end
      end

      def pluralize_string(string, number)
        format(string, number) + (number == 1 ? '' : 's')
      end

      def now
        Time.at(Time.now, in: '+00:00')
      end
    end
  end
end
