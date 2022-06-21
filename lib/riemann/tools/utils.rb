# frozen_string_literal: true

module Riemann
  module Tools
    module Utils # :nodoc:
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
