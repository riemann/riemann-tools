# frozen_string_literal: true

require 'riemann/tools/zpool'

RSpec.describe Riemann::Tools::Zpool do
  context('#tick') do
    before do
      process_status = double
      allow(process_status).to receive(:success?).and_return(true)
      allow(Open3).to receive(:capture2e).with('zpool status -x').and_return([File.read(zpool_output), process_status])
    end

    context 'when pools are healthy' do
      let(:zpool_output) { 'spec/fixtures/zpool/healthy' }

      it 'reports ok state' do
        allow(subject).to receive(:report)
        subject.tick
        expect(subject).to have_received(:report).with(service: 'zpool health', message: "all pools are healthy\n", state: 'ok')
      end
    end

    context 'when pools are degraded' do
      let(:zpool_output) { 'spec/fixtures/zpool/degraded' }

      it 'reports critical state' do
        allow(subject).to receive(:report)
        subject.tick
        expect(subject).to have_received(:report).with(service: 'zpool health', message: /DEGRADED/, state: 'critical')
      end
    end
  end
end
