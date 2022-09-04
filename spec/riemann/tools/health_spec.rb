# frozen_string_literal: true

require 'riemann/tools/health'

RSpec.describe Riemann::Tools::Health do
  context('#disks') do
    before do
      allow(subject).to receive(:df).and_return(<<~OUTPUT)
        Filesystem                         512-blocks       Used      Avail Capacity  Mounted on
        zroot/ROOT/13.1                     643127648   46210936  596916712     7%    /
        zroot/var/audit                     596916888        176  596916712     0%    /var/audit
        zroot/var/mail                      596919416       2704  596916712     0%    /var/mail
        zroot/tmp                           596999464      82752  596916712     0%    /tmp
        zroot                               596916888        176  596916712     0%    /zroot
        zroot/var/crash                     596916888        176  596916712     0%    /var/crash
        zroot/usr/src                       596916888        176  596916712     0%    /usr/src
        zroot/usr/home                      891927992  295011280  596916712    33%    /usr/home
        zroot/var/tmp                       596916952        240  596916712     0%    /var/tmp
        zroot/var/log                       596928976      12264  596916712     0%    /var/log
        192.168.42.5:/volume1/tank/Medias  7491362496 2989541992 4501820504    40%    /usr/home/romain/Medias
      OUTPUT
    end

    it 'reports all zfs filesystems' do
      allow(subject).to receive(:alert).with('disk /', :ok, 0.07185344331519083, '7% used')
      allow(subject).to receive(:alert).with('disk /var/audit', :ok, 2.9484841782529697e-07, '0% used')
      allow(subject).to receive(:alert).with('disk /var/mail', :ok, 4.529924689197913e-06, '0% used')
      allow(subject).to receive(:alert).with('disk /tmp', :ok, 0.0001386131897766662, '0% used')
      allow(subject).to receive(:alert).with('disk /zroot', :ok, 2.9484841782529697e-07, '0% used')
      allow(subject).to receive(:alert).with('disk /var/crash', :ok, 2.9484841782529697e-07, '0% used')
      allow(subject).to receive(:alert).with('disk /usr/src', :ok, 2.9484841782529697e-07, '0% used')
      allow(subject).to receive(:alert).with('disk /usr/home', :ok, 0.33075683535672684, '33% used')
      allow(subject).to receive(:alert).with('disk /var/tmp', :ok, 4.02065981198671e-07, '0% used')
      allow(subject).to receive(:alert).with('disk /var/log', :ok, 2.0545157787749945e-05, '0% used')
      allow(subject).to receive(:alert).with('disk /usr/home/romain/Medias', :ok, 0.39906518922242257, '40% used')
      subject.disk
      expect(subject).to have_received(:alert).with('disk /', :ok, 0.07185344331519083, '7% used')
      expect(subject).to have_received(:alert).with('disk /var/audit', :ok, 2.9484841782529697e-07, '0% used')
      expect(subject).to have_received(:alert).with('disk /var/mail', :ok, 4.529924689197913e-06, '0% used')
      expect(subject).to have_received(:alert).with('disk /tmp', :ok, 0.0001386131897766662, '0% used')
      expect(subject).to have_received(:alert).with('disk /zroot', :ok, 2.9484841782529697e-07, '0% used')
      expect(subject).to have_received(:alert).with('disk /var/crash', :ok, 2.9484841782529697e-07, '0% used')
      expect(subject).to have_received(:alert).with('disk /usr/src', :ok, 2.9484841782529697e-07, '0% used')
      expect(subject).to have_received(:alert).with('disk /usr/home', :ok, 0.33075683535672684, '33% used')
      expect(subject).to have_received(:alert).with('disk /var/tmp', :ok, 4.02065981198671e-07, '0% used')
      expect(subject).to have_received(:alert).with('disk /var/log', :ok, 2.0545157787749945e-05, '0% used')
      expect(subject).to have_received(:alert).with('disk /usr/home/romain/Medias', :ok, 0.39906518922242257, '40% used')
    end
  end

  context '#bsd_swap' do
    context 'with swap devices' do
      before do
        allow(subject).to receive(:`).with('swapinfo').and_return(<<~OUTPUT)
          Device          512-blocks     Used    Avail Capacity
          /dev/da0p2         4194304  2695808  1498496    64%
          /dev/ggate0           2048        0     2048     0%
          Total              4196352  2695808  1500544    64%
        OUTPUT
      end

      it 'reports correct values' do
        allow(subject).to receive(:report_pct).with(:swap, 0.6424170326988775, 'used')
        subject.bsd_swap
        expect(subject).to have_received(:report_pct).with(:swap, 0.6424170326988775, 'used')
      end
    end

    context 'without swap devices' do
      before do
        allow(subject).to receive(:`).with('swapinfo').and_return(<<~OUTPUT)
          Device          512-blocks     Used    Avail Capacity
        OUTPUT
      end

      it 'reports no value' do
        allow(subject).to receive(:report_pct)
        subject.bsd_swap
        expect(subject).not_to have_received(:report_pct)
      end
    end
  end

  context '#linux_swap' do
    context 'with swap devices' do
      before do
        allow(File).to receive(:read).with('/proc/swaps').and_return(<<~OUTPUT)
          Filename				Type		Size		Used		Priority
          /dev/sdb4                               partition	4193276		2848268		-2
          /dev/sda4                               partition	4193276		0		-3
        OUTPUT
      end

      it 'reports correct values' do
        allow(subject).to receive(:report_pct).with(:swap, 0.339623244451355, 'used')
        subject.linux_swap
        expect(subject).to have_received(:report_pct).with(:swap, 0.339623244451355, 'used')
      end
    end
    context 'without swap devices' do
      before do
        allow(File).to receive(:read).with('/proc/swaps').and_return(<<~OUTPUT)
          Filename				Type		Size		Used		Priority
        OUTPUT
      end

      it 'reports no value' do
        allow(subject).to receive(:report_pct)
        subject.linux_swap
        expect(subject).not_to have_received(:report_pct)
      end
    end
  end

  context '#bsd_uptime' do
    context 'when given unexpected data' do
      before do
        allow(subject).to receive(:`).with('uptime').and_return(<<~DOCUMENT)
          10:27:42 up 20:05,  load averages: 0.79, 0.50, 0.44
        DOCUMENT
      end

      it 'reports critical state' do
        allow(subject).to receive(:report)
        subject.bsd_uptime
        expect(subject).to have_received(:report).with(service: 'uptime', description: <<~DESCRIPTION.chomp, state: 'critical')
          Error parsing uptime: parse error on value "load averages:" (LOAD_AVERAGES) on line 1:
          10:27:42 up 20:05,  load averages: 0.79, 0.50, 0.44
                              ^~~~~~~~~~~~~~
        DESCRIPTION
      end
    end

    context 'when given malformed data' do
      before do
        allow(subject).to receive(:`).with('uptime').and_return(<<~DOCUMENT)
          10:27:42 up 20:05,  1 user,  load average: 0.79, 0.50, 0.44 [IO: 0.15, 0.12, 0.08 CPU: 0.64, 0.38, 0.35]
        DOCUMENT
      end

      it 'reports critical state' do
        allow(subject).to receive(:report)
        subject.bsd_uptime
        expect(subject).to have_received(:report).with(service: 'uptime', description: <<~DESCRIPTION.chomp, state: 'critical')
          Error parsing uptime: unexpected data on line 1:
          10:27:42 up 20:05,  1 user,  load average: 0.79, 0.50, 0.44 [IO: 0.15, 0.12, 0.08 CPU: 0.64, 0.38, 0.35]
                                                                      ^
        DESCRIPTION
      end
    end
  end
end
