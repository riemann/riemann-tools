# frozen_string_literal: true

require 'riemann/tools/net'

RSpec.describe Riemann::Tools::Net do
  context('#state') do
    let(:state) { subject.state }
    it 'finds all interfaces' do
      allow(File).to receive(:read).with('/proc/net/dev').and_return(<<~CONTENT)
      Inter-|   Receive                                                |  Transmit
       face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
          lo: 165480372  191253    0    0    0     0          0         0 165480372  191253    0    0    0     0       0          0
      enp2s0: 1318001616 2106881    0    0    0     0          0         1 162233326 1866816    0    0    0     0       0          0
      docker0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
      br-1c33f552db55:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
      CONTENT

      expect(state).to eq({
       "docker0 rx bytes" => 0,
       "docker0 rx compressed" => 0,
       "docker0 rx drop" => 0,
       "docker0 rx errs" => 0,
       "docker0 rx fifo" => 0,
       "docker0 rx frame" => 0,
       "docker0 rx multicast" => 0,
       "docker0 rx packets" => 0,
       "docker0 tx bytes" => 0,
       "docker0 tx carrier" => 0,
       "docker0 tx colls" => 0,
       "docker0 tx compressed" => 0,
       "docker0 tx drops" => 0,
       "docker0 tx errs" => 0,
       "docker0 tx fifo" => 0,
       "docker0 tx packets" => 0,
       "enp2s0 rx bytes" => 1318001616,
       "enp2s0 rx compressed" => 0,
       "enp2s0 rx drop" => 0,
       "enp2s0 rx errs" => 0,
       "enp2s0 rx fifo" => 0,
       "enp2s0 rx frame" => 0,
       "enp2s0 rx multicast" => 1,
       "enp2s0 rx packets" => 2106881,
       "enp2s0 tx bytes" => 162233326,
       "enp2s0 tx carrier" => 0,
       "enp2s0 tx colls" => 0,
       "enp2s0 tx compressed" => 0,
       "enp2s0 tx drops" => 0,
       "enp2s0 tx errs" => 0,
       "enp2s0 tx fifo" => 0,
       "enp2s0 tx packets" => 1866816,
       "br-1c33f552db55 rx bytes" => 0,
       "br-1c33f552db55 rx compressed" => 0,
       "br-1c33f552db55 rx drop" => 0,
       "br-1c33f552db55 rx errs" => 0,
       "br-1c33f552db55 rx fifo" => 0,
       "br-1c33f552db55 rx frame" => 0,
       "br-1c33f552db55 rx multicast" => 0,
       "br-1c33f552db55 rx packets" => 0,
       "br-1c33f552db55 tx bytes" => 0,
       "br-1c33f552db55 tx carrier" => 0,
       "br-1c33f552db55 tx colls" => 0,
       "br-1c33f552db55 tx compressed" => 0,
       "br-1c33f552db55 tx drops" => 0,
       "br-1c33f552db55 tx errs" => 0,
       "br-1c33f552db55 tx fifo" => 0,
       "br-1c33f552db55 tx packets" => 0,
      })
    end

    it 'select interfaces using regexp' do
      subject.instance_variable_set('@interfaces', ['enp'])
      subject.instance_variable_set('@ignore_interfaces', [])
      allow(File).to receive(:read).with('/proc/net/dev').and_return(<<~CONTENT)
      Inter-|   Receive                                                |  Transmit
       face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
          lo: 165480372  191253    0    0    0     0          0         0 165480372  191253    0    0    0     0       0          0
      enp2s0: 1318001616 2106881    0    0    0     0          0         1 162233326 1866816    0    0    0     0       0          0
      docker0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
      br-1c33f552db55:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
      CONTENT

      expect(state).not_to include({ "lo rx bytes" => 165480372 })
      expect(state).to include({ "enp2s0 rx bytes" => 1318001616 })
      expect(state).not_to include({ "docker0 rx bytes" => 0 })
      expect(state).not_to include({ "br-1c33f552db55 rx bytes" => 0 })
    end

    it 'ignore interfaces using regexp' do
      subject.instance_variable_set('@ignore_interfaces', ['br'])
      allow(File).to receive(:read).with('/proc/net/dev').and_return(<<~CONTENT)
      Inter-|   Receive                                                |  Transmit
       face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
          lo: 165480372  191253    0    0    0     0          0         0 165480372  191253    0    0    0     0       0          0
      enp2s0: 1318001616 2106881    0    0    0     0          0         1 162233326 1866816    0    0    0     0       0          0
      docker0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
      br-1c33f552db55:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
      CONTENT

      expect(state).to include({ "lo rx bytes" => 165480372 })
      expect(state).to include({ "enp2s0 rx bytes" => 1318001616 })
      expect(state).to include({ "docker0 rx bytes" => 0 })
      expect(state).not_to include({ "br-1c33f552db55 rx bytes" => 0 })
    end
  end
end
