# frozen_string_literal: true

require 'riemann/tools/md'

RSpec.describe Riemann::Tools::Md do
  context('#tick') do
    context 'when all md devices are healthy' do
      before do
        allow(File).to receive(:read).with('/proc/mdstat').and_return(File.read('spec/fixtures/mdstat/example-8'))
      end

      it 'reports ok state' do
        allow(subject).to receive(:report)
        subject.tick
        expect(subject).to have_received(:report).with(service: 'mdstat', message: //, state: 'ok')
      end
    end

    context 'when md devices are unhealthy' do
      before do
        allow(File).to receive(:read).with('/proc/mdstat').and_return(File.read('spec/fixtures/mdstat/example-9'))
      end

      it 'reports critical state' do
        allow(subject).to receive(:report)
        subject.tick
        expect(subject).to have_received(:report).with(service: 'mdstat', message: //, state: 'critical')
      end
    end
  end
end
