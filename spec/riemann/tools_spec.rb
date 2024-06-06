# frozen_string_literal: true

require 'riemann/tools/health'

class ExampleTool
  include Riemann::Tools
end

RSpec.describe Riemann::Tools do
  describe '#options' do
    describe ':ttl' do
      subject(:tool) { ExampleTool.new }

      {
        ''                           => 10,
        '--ttl=60'                   => 60,
        '--interval 10'              => 20,
        '--minimum-ttl 300'          => 300,
        '--minimum-ttl 300 --ttl=60' => 300,
        '--minimum-ttl 30 --ttl 60'  => 60,
      }.each do |argv, expected_ttl|
        context "with ARGV=\"#{argv}\"" do
          before do
            ARGV.replace argv.split
          end

          it { expect(tool.options[:ttl]).to eq expected_ttl }
        end
      end
    end
  end
end
