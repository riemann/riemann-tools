# frozen_string_literal: true

require 'riemann/tools/hwmon'

RSpec.describe Riemann::Tools::Hwmon::Device do
  subject { described_class.new(1, :temp, 2) }

  before do
    allow(File).to receive(:realpath).with('/sys/class/hwmon/hwmon1/name').and_return(device_path)
    allow(File).to receive(:read).with('/sys/class/hwmon/hwmon1/name').and_return("i350bb\n")
    allow(File).to receive(:read).with('/sys/class/hwmon/hwmon1/temp2_crit').and_return("96000\n")
    allow(File).to receive(:read).with('/sys/class/hwmon/hwmon1/temp2_lcrit').and_raise(Errno::ENOENT)
    allow(File).to receive(:read).with('/sys/class/hwmon/hwmon1/temp2_label').and_return("loc1\n")
  end

  let(:device_path) { '/sys/devices/platform/coretemp.0/hwmon/hwmon1' }

  describe '#name' do
    context 'with a regular device' do
      it { expect(subject.name).to eq('i350bb') }
    end

    context 'with an i2c device' do
      let(:device_path) { '/sys/devices/pci0000:00/0000:00:1f.3/i2c-1/1-001a/hwmon/hwmon1' }

      it { expect(subject.name).to eq('i350bb at i2c-1/1-001a') }
    end
  end

  describe '#report' do
    before do
      allow(File).to receive(:read).with('/sys/class/hwmon/hwmon1/temp2_input').and_return("#{input}\n")
    end

    context 'when temperature is ok' do
      let(:input) { 31_000 }

      it { expect(subject.report).to eq({ service: 'hwmon i350bb loc1', state: :ok, metric: 31.0, description: '31.000 °C' }) }
    end

    context 'when temperature is critical' do
      let(:input) { 96_000 }

      it { expect(subject.report).to eq({ service: 'hwmon i350bb loc1', state: :critical, metric: 96.0, description: '96.000 °C' }) }
    end
  end
end
