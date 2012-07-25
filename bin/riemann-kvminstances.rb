require File.expand_path('../../lib/riemann/tools', __FILE__)

class Riemann::Tools::KVM
  include Riemann::Tools

  def tick

  #determine how many instances I have according to libvirt
  kvm_instances = %x[virsh list |grep i-|wc -l]

  #submit them to riemann
  report(
     :service => "KVM Running VMs",
     :metric => kvm_instances,
     :state => "info"
       )
  end
end

Riemann::Tools::KVM.run