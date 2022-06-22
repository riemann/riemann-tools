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
      allow(subject).to receive(:alert).with('disk /', :ok, 0.07, '7% used')
      allow(subject).to receive(:alert).with('disk /var/audit', :ok, 0, '0% used')
      allow(subject).to receive(:alert).with('disk /var/mail', :ok, 0, '0% used')
      allow(subject).to receive(:alert).with('disk /tmp', :ok, 0, '0% used')
      allow(subject).to receive(:alert).with('disk /zroot', :ok, 0, '0% used')
      allow(subject).to receive(:alert).with('disk /var/crash', :ok, 0, '0% used')
      allow(subject).to receive(:alert).with('disk /usr/src', :ok, 0, '0% used')
      allow(subject).to receive(:alert).with('disk /usr/home', :ok, 0.33, '33% used')
      allow(subject).to receive(:alert).with('disk /var/tmp', :ok, 0, '0% used')
      allow(subject).to receive(:alert).with('disk /var/log', :ok, 0, '0% used')
      allow(subject).to receive(:alert).with('disk /usr/home/romain/Medias', :ok, 0.4, '40% used')
      subject.disk
      expect(subject).to have_received(:alert).with('disk /', :ok, 0.07, '7% used')
      expect(subject).to have_received(:alert).with('disk /var/audit', :ok, 0, '0% used')
      expect(subject).to have_received(:alert).with('disk /var/mail', :ok, 0, '0% used')
      expect(subject).to have_received(:alert).with('disk /tmp', :ok, 0, '0% used')
      expect(subject).to have_received(:alert).with('disk /zroot', :ok, 0, '0% used')
      expect(subject).to have_received(:alert).with('disk /var/crash', :ok, 0, '0% used')
      expect(subject).to have_received(:alert).with('disk /usr/src', :ok, 0, '0% used')
      expect(subject).to have_received(:alert).with('disk /usr/home', :ok, 0.33, '33% used')
      expect(subject).to have_received(:alert).with('disk /var/tmp', :ok, 0, '0% used')
      expect(subject).to have_received(:alert).with('disk /var/log', :ok, 0, '0% used')
      expect(subject).to have_received(:alert).with('disk /usr/home/romain/Medias', :ok, 0.4, '40% used')
    end
  end
end
