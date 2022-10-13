# frozen_string_literal: true

require 'riemann/tools/net'

RSpec.describe Riemann::Tools::Net do
  context('#report_interface?') do
    it 'selects interfaces by name' do
      subject.instance_variable_set(:@interfaces, %w[wlan0 wlan1])
      subject.instance_variable_set(:@ignore_interfaces, %w[wlan1])

      expect(subject.report_interface?('wlan0')).to be_truthy
      expect(subject.report_interface?('wlan1')).to be_truthy
    end

    it 'selects interfaces by regular expression' do
      subject.instance_variable_set(:@interfaces, %w[\Awlan\d+\z])
      subject.instance_variable_set(:@ignore_interfaces, %w[wlan1])

      expect(subject.report_interface?('wlan0')).to be_truthy
      expect(subject.report_interface?('wlan1')).to be_truthy
    end

    it 'reject interfaces by name' do
      subject.instance_variable_set(:@interfaces, [])
      subject.instance_variable_set(:@ignore_interfaces, %w[wlan1])

      expect(subject.report_interface?('wlan0')).to be_truthy
      expect(subject.report_interface?('wlan1')).to be_falsey
    end

    it 'reject interfaces by regular expression' do
      subject.instance_variable_set(:@interfaces, [])
      subject.instance_variable_set(:@ignore_interfaces, %w[\Awlan\d+\z])

      expect(subject.report_interface?('wlan0')).to be_falsey
      expect(subject.report_interface?('wlan1')).to be_falsey
    end
  end

  context('#freebsd_state') do
    let(:freebsd_state) { subject.freebsd_state }
    it 'finds all interfaces' do
      allow(subject).to receive(:`).with('netstat -inb --libxo=json').and_return('{"statistics": {"interface": [{"name":"vtnet0","flags":"0x8863","mtu":1500,"network":"<Link#1>","address":"96:00:00:7b:2f:db","received-packets":14409097,"received-errors":0,"dropped-packets":0,"received-bytes":3661133356,"sent-packets":14006498,"send-errors":0,"sent-bytes":4606661018,"collisions":0}, {"name":"vtnet0","flags":"0x8863","network":"2a01:4f9:c010:e1dd::/64","address":"2a01:4f9:c010:e1dd::","received-packets":4072295,"received-bytes":4334205829,"sent-packets":2423184,"sent-bytes":473948371}, {"name":"vtnet0","flags":"0x8863","network":"fe80::%vtnet0/64","address":"fe80::9400:ff:fe7b:2fdb%vtnet0","received-packets":60737,"received-bytes":3887168,"sent-packets":60739,"sent-bytes":4373236}, {"name":"vtnet0","flags":"0x8863","network":"135.181.146.104/32","address":"135.181.146.104","received-packets":11897156,"received-bytes":2242504526,"sent-packets":12708744,"sent-bytes":4372534465}, {"name":"lo0","flags":"0x8049","mtu":16384,"network":"<Link#2>","address":"lo0","received-packets":18539596,"received-errors":0,"dropped-packets":0,"received-bytes":7314451024,"sent-packets":18539596,"send-errors":0,"sent-bytes":7314451024,"collisions":0}, {"name":"lo0","flags":"0x8049","network":"::1/128","address":"::1","received-packets":6726995,"received-bytes":2429478036,"sent-packets":8462601,"sent-bytes":5178849236}, {"name":"lo0","flags":"0x8049","network":"fe80::%lo0/64","address":"fe80::1%lo0","received-packets":0,"received-bytes":0,"sent-packets":0,"sent-bytes":0}, {"name":"lo0","flags":"0x8049","network":"127.0.0.0/8","address":"127.0.0.1","received-packets":9480200,"received-bytes":1729579367,"sent-packets":9480200,"sent-bytes":1729579367}]}}')

      expect(freebsd_state).to eq(
        'vtnet0 rx bytes'   => 3_661_133_356,
        'vtnet0 rx packets' => 14_409_097,
        'vtnet0 rx errs'    => 0,
        'vtnet0 tx bytes'   => 4_606_661_018,
        'vtnet0 tx packets' => 14_006_498,
        'vtnet0 tx errs'    => 0,
        'vtnet0 rx drop'    => 0,
        'vtnet0 tx colls'   => 0,
      )
    end
  end

  context('#linux_state') do
    let(:linux_state) { subject.linux_state }
    it 'finds all interfaces' do
      allow(File).to receive(:read).with('/proc/net/dev').and_return(<<~CONTENT)
        Inter-|   Receive                                                |  Transmit
         face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
            lo: 165480372  191253    0    0    0     0          0         0 165480372  191253    0    0    0     0       0          0
        enp2s0: 1318001616 2106881    0    0    0     0          0         1 162233326 1866816    0    0    0     0       0          0
        docker0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
        br-1c33f552db55:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
      CONTENT

      expect(linux_state).to eq(
        'docker0 rx bytes'              => 0,
        'docker0 rx compressed'         => 0,
        'docker0 rx drop'               => 0,
        'docker0 rx errs'               => 0,
        'docker0 rx fifo'               => 0,
        'docker0 rx frame'              => 0,
        'docker0 rx multicast'          => 0,
        'docker0 rx packets'            => 0,
        'docker0 tx bytes'              => 0,
        'docker0 tx carrier'            => 0,
        'docker0 tx colls'              => 0,
        'docker0 tx compressed'         => 0,
        'docker0 tx drop'               => 0,
        'docker0 tx errs'               => 0,
        'docker0 tx fifo'               => 0,
        'docker0 tx packets'            => 0,
        'enp2s0 rx bytes'               => 1_318_001_616,
        'enp2s0 rx compressed'          => 0,
        'enp2s0 rx drop'                => 0,
        'enp2s0 rx errs'                => 0,
        'enp2s0 rx fifo'                => 0,
        'enp2s0 rx frame'               => 0,
        'enp2s0 rx multicast'           => 1,
        'enp2s0 rx packets'             => 2_106_881,
        'enp2s0 tx bytes'               => 162_233_326,
        'enp2s0 tx carrier'             => 0,
        'enp2s0 tx colls'               => 0,
        'enp2s0 tx compressed'          => 0,
        'enp2s0 tx drop'                => 0,
        'enp2s0 tx errs'                => 0,
        'enp2s0 tx fifo'                => 0,
        'enp2s0 tx packets'             => 1_866_816,
        'br-1c33f552db55 rx bytes'      => 0,
        'br-1c33f552db55 rx compressed' => 0,
        'br-1c33f552db55 rx drop'       => 0,
        'br-1c33f552db55 rx errs'       => 0,
        'br-1c33f552db55 rx fifo'       => 0,
        'br-1c33f552db55 rx frame'      => 0,
        'br-1c33f552db55 rx multicast'  => 0,
        'br-1c33f552db55 rx packets'    => 0,
        'br-1c33f552db55 tx bytes'      => 0,
        'br-1c33f552db55 tx carrier'    => 0,
        'br-1c33f552db55 tx colls'      => 0,
        'br-1c33f552db55 tx compressed' => 0,
        'br-1c33f552db55 tx drop'       => 0,
        'br-1c33f552db55 tx errs'       => 0,
        'br-1c33f552db55 tx fifo'       => 0,
        'br-1c33f552db55 tx packets'    => 0,
      )
    end
  end
end
