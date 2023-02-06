# frozen_string_literal: true

require 'riemann/tools/riemann_client_wrapper'

RSpec.describe Riemann::Tools::RiemannClientWrapper do
  subject do
    instance = described_class.new({})
    client_mock = double
    allow(client_mock).to receive(:bulk_send)
    allow(instance).to receive(:client).and_return(client_mock)
    instance
  end

  describe '#drain' do
    it 'accepts events before draining' do
      expect { subject << {} }.not_to raise_error
    end

    it 'does not accept events when draining' do
      subject.drain
      expect { subject << {} }.to raise_error(RuntimeError, 'Cannot queue events when draining')
    end
  end
end
