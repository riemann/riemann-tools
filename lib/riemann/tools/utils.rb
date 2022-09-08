# frozen_string_literal: true

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
    end
  end
end
