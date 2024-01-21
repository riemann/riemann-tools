# frozen_string_literal: true

require 'riemann/tools/utils'

class TestClass
  include Riemann::Tools::Utils
end

RSpec.describe Riemann::Tools::Utils do
  describe('#reverse_numeric_sort_with_header') do
    subject { TestClass.new.reverse_numeric_sort_with_header(input) }

    let(:input) do
      <<~INPUT
        Header
        11
         1
         2
         8
        10
         3
         4
        14
         5
        12
         7
        13
        15
         9
         6
      INPUT
    end
    it { is_expected.to eq("Header\n15\n14\n13\n12\n11\n10\n 9\n 8\n 7\n 6") }

    context 'with a number of data lines' do
      subject { TestClass.new.reverse_numeric_sort_with_header(input, count: 3) }
      it { is_expected.to eq("Header\n15\n14\n13") }
    end

    context 'with a number of header lines' do
      subject { TestClass.new.reverse_numeric_sort_with_header(input, header: 3) }
      it { is_expected.to eq("Header\n11\n 1\n15\n14\n13\n12\n10\n 9\n 8\n 7\n 6\n 5") }
    end
  end
end
