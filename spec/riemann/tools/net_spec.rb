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
                          })
    end
  end
end
