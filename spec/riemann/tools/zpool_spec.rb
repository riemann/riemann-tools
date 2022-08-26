# frozen_string_literal: true

require 'riemann/tools/zpool'

RSpec.describe Riemann::Tools::Zpool do
  context('#tick') do
    context 'when pools are healthy' do
      before do
        process_status = double
        allow(process_status).to receive(:success?).and_return(true)
        allow(Open3).to receive(:capture2e).with('zpool status -x').and_return(["all pools are healthy\n", process_status])
      end

      it 'reports ok state' do
        allow(subject).to receive(:report)
        subject.tick
        expect(subject).to have_received(:report).with(service: 'zpool health', message: "all pools are healthy\n", state: 'ok')
      end
    end

    context 'when pools are unhealthy' do
      before do
        process_status = double
        allow(process_status).to receive(:success?).and_return(false)
        allow(Open3).to receive(:capture2e).with('zpool status -x').and_return(['details', process_status])
      end

      it 'reports critical state' do
        allow(subject).to receive(:report)
        subject.tick
        expect(subject).to have_received(:report).with(service: 'zpool health', message: 'details', state: 'critical')
      end
    end
  end
end
