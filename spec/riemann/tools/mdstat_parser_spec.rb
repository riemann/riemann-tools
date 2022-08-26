# frozen_string_literal: true

require 'riemann/tools/mdstat_parser.tab'

RSpec.describe Riemann::Tools::MdstatParser do
  {
    'example-1'  => {},
    'example-2'  => {},
    'example-3'  => { 'md2' => 'UU' },
    'example-4'  => { 'md4' => 'UU', 'md2' => 'UU', 'md3' => 'UU' },
    'example-5'  => { 'md2' => 'UU', 'md1' => 'UU___', 'md0' => 'UU___' },
    # Examples from https://raid.wiki.kernel.org/index.php/Mdstat
    'example-6'  => { 'md_d0' => 'UUUUU' },
    'example-7'  => { 'md0' => 'UUU_' },
    'example-8'  => { 'md1' => 'UU', 'md2' => 'UU', 'md3' => 'UUUUUUUUUU', 'md0' => 'UU' },
    'example-9'  => { 'md127' => 'UUUUU_' },
    'example-10' => { 'md0' => 'UUUUUUU' },
    'example-11' => { 'md1' => '_UUUU_' },
  }.each do |config, expected_data|
    describe(config) do
      let(:text) { File.read("spec/fixtures/mdstat/#{config}") }

      it 'parses successfuly' do
        expect { subject.parse(text) }.not_to raise_error
      end

      it 'parses correct satus' do
        expect(subject.parse(text)).to eq(expected_data)
      end
    end
  end
end
