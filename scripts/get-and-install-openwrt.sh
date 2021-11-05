#!/bin/bash
## OpenWRT 15.05 router Firewall with two interfaces
# Fix variables
name=$1
router_name=router-$name
url=https://downloads.openwrt.org/chaos_calmer/15.05/x86/kvm_guest/openwrt-15.05-x86-kvm_guest-combined-ext4.img.gz
destination=/var/lib/libvirt/images/
parameters=$#

check_parameters () {
# Check parameters
if [ $parameters -ne 1 ]; then
echo "Please provide the name" ; exit
exit
fi
# Check the name
if grep -qw ${router_name} <<< $(virsh list --all --name)  ; then
echo "Please provide a guest name that is not in use : exit"
exit
fi
}

bridges_creation () {
# bridges creation
./add-bridge.sh lan-$name isolated
./add-bridge.sh internet-$name full
}

openwrt_installation () {
# Get and decompresse image
wget $url -O $destination$router_name.img.gz
gunzip $destination$router_name.img.gz
# Install the guest
virt-install --name=$router_name \
--ram=128 --vcpus=1 \
--os-type=linux \
--disk path=$destination$router_name.img,bus=ide \
--network bridge=lan-$name,model=virtio \
--network bridge=internet-$name,model=virtio \
--import  \
--noautoconsole
}

check_parameters
bridges_creation
openwrt_installation
