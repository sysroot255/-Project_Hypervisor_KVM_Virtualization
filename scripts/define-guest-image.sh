#!/bin/bash
## This script import and launch minimal KVM images with a text console         ##
## First download all the qcow2 images on https://download.goffinet.org/kvm/         ##
## Usage : bash define-guest.sh <name> <image>                                  ##
## Reset root password with the procedure :                                     ##
## https://linux.goffinet.org/06-02-demarrage-du-systeme-linux/#5-password-recovery##
##################################################################################
## Please check all the variables
# First parmater as name
name=$1
# Secund parameter image name available on "https://download.goffinet.org/kvm/"
#imagename="centos7 bionic debian10"
which curl > /dev/null || ( echo "Please install curl" && exit )
imagename="$(curl -kqs https://download.goffinet.org/kvm/imagename)"
image="$2.qcow2"
# Generate an unique string
uuid=$(uuidgen -t)
# Nested (default no)
nested=""
#nested="--cpu host-passthrough"
# VCPUs
vcpu="1"
# The new guest disk name
disk="${name}-${uuid}.qcow2"
# Diskbus can be 'ide', 'scsi', 'usb', 'virtio' or 'xen'
diskbus="virtio"
size="8"
# Hypervisor can be 'qemu', 'kvm' or 'xen'
hypervisor="kvm"
# RAM in Mb
memory="1024"
# Graphics 'none' or 'vnc'
graphics="none"
# Network interface and model 'virtio' or 'rtl8139' or 'e1000'
interface="virbr0"
model="virtio"
# osinfo-query os
if [ $image = "almalinux8.qcow2" ]; then
os="centos7.0"
fi
if [ $image = "bionic.qcow2" ]; then
os="ubuntu18.04"
fi
if [ $image = "debian10.qcow2" ]; then
os="debian9"
fi
if [ $image = "centos7.qcow2" ]; then
os="centos7.0"
fi
if [ $image = "centos8.qcow2" ]; then
os="centos7.0"
fi
if [ $image = "focal.qcow2" ]; then
os="ubuntu18.04"
fi
if [ $image = "fedora32.qcow2" ]; then
os="fedora28"
fi
if [ $image = "fedora33.qcow2" ]; then
os="fedora28"
fi
if [ $image = "fedora34.qcow2" ]; then
os="fedora28"
fi
if [ $image = "rocky8.qcow2" ]; then
os="centos7.0"
fi
# Parameters for metasploitable guests
if [ $image = "metasploitable.qcow2" ]; then
diskbus="scsi"
model="e1000"
fi
# Parameters for Kali guests
if [ $image = "kali2021.qcow2" ]; then
memory="1024"
os="debian9"
fi
if [ $image = "gns3.qcow2" ]; then
memory="2048"
nested="--cpu host-passthrough"
fi

## Download the image dialog function : list, choice, sure, download
usage_message () {
echo "Usage : $0 <name> <image>"
echo "Please download one of those images in /var/lib/libvirt/images :"
for x in $imagename ; do
echo "https://download.goffinet.org/kvm/${x}.qcow2"
done
}

## Check parameters
# check "$#" -lt 2
if [ "$#" -ne 2  ] ; then
usage_message
exit
fi
# check a valid image name
if grep -qvw "$2" <<< "$imagename" ; then
usage_message
exit
fi
# check the presence of the image
if [ ! -f /var/lib/libvirt/images/${image}  ] ; then
usage_message
exit
fi
# Check the usage of the requested domain
if grep -qw ${name} <<< $(virsh list --all --name)  ; then
echo "Please provide an other guest name : exit"
exit
fi

## Linked image copy to the default storage pool ##
#cp /var/lib/libvirt/images/$image /var/lib/libvirt/images/$disk
qemu-img create -f qcow2 -b /var/lib/libvirt/images/$image /var/lib/libvirt/images/$disk

## Customize this new guest disk
if [ $image = "bionic.qcow2" ]; then
sleep 1
virt-sysprep -a /var/lib/libvirt/images/$disk --operations customize --firstboot-command "sudo dbus-uuidgen > /etc/machine-id ; sudo hostnamectl set-hostname $name ; sudo reboot"
fi
if [ $image = "debian10.qcow2" ]; then
sleep 1
virt-sysprep -a /var/lib/libvirt/images/$disk --operations customize --firstboot-command "sudo dbus-uuidgen > /etc/machine-id ; sudo hostnamectl set-hostname $name ; sudo reboot"
fi
if [ $image = "centos7.qcow2" ]; then
sleep 1
virt-sysprep -a /var/lib/libvirt/images/$disk --hostname $name --selinux-relabel  --quiet
fi
if [ $image = "centos8.qcow2" ]; then
sleep 1
virt-sysprep -a /var/lib/libvirt/images/$disk --hostname $name --selinux-relabel  --quiet
fi

## Import and lauch the new guest ##
virt-install \
--virt-type $hypervisor \
--name=$name \
--disk path=/var/lib/libvirt/images/$disk \
--ram=$memory \
--vcpus=$vcpu \
--os-type=linux \
--os-variant=$os \
--network bridge=$interface,model=$model \
--graphics $graphics \
--console pty,target_type=serial \
--import \
--noautoconsole $nested
