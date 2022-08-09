# frozen_string_literal: true

require 'riemann/tools'

module Riemann
  module Tools
    class Kvm
      include Riemann::Tools

      def tick
        # determine how many instances I have according to libvirt
        kvm_instances = `LANG=C virsh list | grep -c running`

        # submit them to riemann
        report(
          service: 'KVM Running VMs',
          metric: kvm_instances.to_i,
          state: 'info',
        )
      end
    end
  end
end
