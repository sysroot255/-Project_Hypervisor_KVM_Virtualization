#!/bin/bash

#imagename="debian7 debian8 debian10 centos7 centos8 ubuntu1604 bionic metasploitable kali arch"
which curl > /dev/null || ( echo "Please install curl" && exit )
imagename="$(curl -kqs https://download.goffinet.org/kvm/imagename)"
image=$4
# Generate an unique string
uuid=$(uuidgen -t)
name=$1
# Nested (default no)
nested=""
#nested="--cpu host-passthrough"
network=$2
# Profiles : xsmall, small, medium, big (and  desktop)
profile=$3
mac=$5
parameters=$#
if [[ $image = "bionic" ]] || [[ $image = "focal" ]] ; then
os="ubuntu18.04"
elif [[ $image = "debian10" ]] || [[ $image = "kali20211" ]] ; then
os="debian9"
elif [[ $image = "centos7" ]] || [[ $image = "centos8" ]] || [[ $image = "centos8-stream" ]] || [[ $image = "almalinux8" ]] || [[ $image = "rocky8" ]] ; then
os="centos7.0"
elif [[ $image = "fedora32" ]] || [[ $image = "fedora33" ]] || [[ $image = "fedora34" ]] ; then
os="fedora28"
else
usage_message
fi
if [[ ! -z "$mac" ]] ; then
mac_param=",mac=$mac"
else
random_mac=$(tr -dc a-f0-9 < /dev/urandom | head -c 10 | sed -r 's/(..)/\1:/g;s/:$//;s/^/02:/')
mac_param=",mac=$random_mac"
mac="$random_mac"
fi

usage_message () {
## Usage message
echo "Usage : $0 <name> <network_name> <profile> <image_name> <mac address>"
echo "Profiles available : xsmall, small, medium, big, desktop"
echo "<mac address> can be omitted"
echo "Example : '$0 server1 internet desktop centos7 00:50:56:00:7F:E0'"
echo "Please download one of those images in /var/lib/libvirt/images :"
for x in $imagename ; do
echo "https://download.goffinet.org/kvm/${x}.qcow2"
done
}

profile_definition () {
# VCPUs
vcpu="1"
# The new guest disk name
disk="${name}-${uuid}.qcow2"
# Diskbus can be 'ide', 'scsi', 'usb', 'virtio' or 'xen'
diskbus="virtio"
size="8"
# Hypervisor can be 'qemu', 'kvm' or 'xen'
hypervisor="kvm"
# Graphics 'none' or 'vnc'
graphics="none"
# RAM in Mb
memory="256"
# Network interface and model 'virtio' or 'rtl8139' or 'e1000'
model="virtio"
case "$profile" in
    xsmall) ;;
    small) memory="512" ;;
    medium) memory="1024" ;;
    big) vcpu="2"
         memory="2048" ;;
    desktop) vcpu="2"
             memory="4096" ;;
    *) usage_message ; exit ;;
esac
}

check_paramters () {
## Check parameters
if [[ "$parameters" -eq 0 ]] ; then usage_message ; exit
#check a valid image name
elif grep -qvw "$image" <<< "$imagename" ; then usage_message ; exit
# check the presence of the image
elif [[ ! -f /var/lib/libvirt/images/${image}.qcow2  ]] ; then usage_message ; exit
# Check the usage of the requested domain
elif grep -qw "$name" <<< $(virsh list --all --name)  ; then echo "Please provide an other guest name : exit" ; exit
# Check the network
elif [[ ! -e /run/libvirt/network/${network}.xml ]] ; then echo "$network network does not exist"
echo "Please create a new one or choose a valid present network : " ; virsh net-list ; exit; fi
}

copy_image () {
## Linked image copy to the default storage pool ##
#cp /var/lib/libvirt/images/$image /var/lib/libvirt/images/$disk
qemu-img create -f qcow2 -b /var/lib/libvirt/images/${image}.qcow2 /var/lib/libvirt/images/$disk
}

customize_new_disk () {
## Customize this new guest disk
if [[ $image = "bionic" ]] ; then
sleep 1
virt-sysprep -a /var/lib/libvirt/images/$disk --operations customize --firstboot-command "sudo dbus-uuidgen > /etc/machine-id ; sudo hostnamectl set-hostname $name ; sudo reboot"
elif [[ $image = "focal" ]] ; then
sleep 1
virt-sysprep -a /var/lib/libvirt/images/$disk --operations customize --firstboot-command "sudo dbus-uuidgen > /etc/machine-id ; sudo hostnamectl set-hostname $name ; sudo reboot"
elif [[ $image = "debian10" ]] ; then
sleep 1
virt-sysprep -a /var/lib/libvirt/images/$disk --operations customize --firstboot-command "sudo dbus-uuidgen > /etc/machine-id ; sudo hostnamectl set-hostname $name ; sudo reboot"
elif [[ $image = "centos7" ]] ; then
virt-sysprep -a /var/lib/libvirt/images/$disk --hostname $name --selinux-relabel  --quiet
fi
}

import_launch () {
## Import and lauch the new guest ##
virt-install \
--virt-type ${hypervisor} \
--name=${name} \
--disk path=/var/lib/libvirt/images/${disk} \
--ram=$memory \
--vcpus=${vcpu} \
--os-type=linux \
--os-variant=${os} \
--network network=${network},model=${model}${mac_param} \
--graphics ${graphics} \
--console pty,target_type=serial \
--import \
--noautoconsole ${nested}
}

start_time="$(date -u +%s)"
check_paramters
profile_definition
copy_image
customize_new_disk
import_launch
end_time="$(date -u +%s)"
echo "Time elapsed $(($end_time-$start_time)) second"
