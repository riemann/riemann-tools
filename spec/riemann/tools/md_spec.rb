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
        expect(subject).to have_received(:report).with(service: 'mdstat md0', description: 'UU', state: 'ok')
        expect(subject).to have_received(:report).with(service: 'mdstat md1', description: 'UU', state: 'ok')
        expect(subject).to have_received(:report).with(service: 'mdstat md2', description: 'UU', state: 'ok')
        expect(subject).to have_received(:report).with(service: 'mdstat md3', description: 'UUUUUUUUUU', state: 'ok')
      end
    end

    context 'when md devices are unhealthy' do
      before do
        allow(File).to receive(:read).with('/proc/mdstat').and_return(File.read('spec/fixtures/mdstat/example-9'))
      end

      it 'reports critical state' do
        allow(subject).to receive(:report)
        subject.tick
        expect(subject).to have_received(:report).with(service: 'mdstat md127', description: 'UUUUU_', state: 'critical')
      end
    end

    context 'when given unexpected data' do
      before do
        allow(File).to receive(:read).with('/proc/mdstat').and_return(<<~DOCUMENT)
          Personalities : [raid1]
          md2 : active raid1 sda3[0] sdb3[2]
                3902196544 blocks super 1.2 [2/2] [UU]
                42 splines reticulated

          md1 : active raid1 sda2[0] sdb2[1]
                2097088 blocks [5/2] [UU___]

          md0 : active raid1 sda1[0] sdb1[1]
                2490176 blocks [5/2] [UU___]

          unused devices: <none>
        DOCUMENT
      end

      it 'reports critical state' do
        allow(subject).to receive(:report)
        subject.tick
        expect(subject).to have_received(:report).with(service: 'mdstat', description: <<~DESCRIPTION.chomp, state: 'critical')
          Error parsing mdstat: parse error on value "42" (INTEGER) on line 4:
                42 splines reticulated
                ^~
        DESCRIPTION
      end
    end

    context 'when given malformed data' do
      before do
        allow(File).to receive(:read).with('/proc/mdstat').and_return(<<~DOCUMENT)
          Personalities : [raid1]
          md2 : active raid1+ sda3[0] sdb3[2]
                3902196544 blocks super 1.2 [2/2] [UU]

          md1 : active raid1+ sda2[0] sdb2[1]
                2097088 blocks [5/2] [UU___]

          md0 : active raid1+ sda1[0] sdb1[1]
                2490176 blocks [5/2] [UU___]

          unused devices: <none>
        DOCUMENT
      end

      it 'reports critical state' do
        allow(subject).to receive(:report)
        subject.tick
        expect(subject).to have_received(:report).with(service: 'mdstat', description: <<~DESCRIPTION.chomp, state: 'critical')
          Error parsing mdstat: unexpected data on line 2:
          md2 : active raid1+ sda3[0] sdb3[2]
                            ^
        DESCRIPTION
      end
    end
  end
end
