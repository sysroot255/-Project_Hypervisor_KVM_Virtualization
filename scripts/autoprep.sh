#!/bin/bash
#Setup KVM/Libvirtd/LibguestFS on RHEL7/Centos 7/Debian Jessie.

check_distribution () {
if [ -f /etc/debian_version ]; then
debian8_prep
virsh net-start default
virsh net-autostart default
elif [ -f /etc/redhat-release ]; then
centos7_prep
fi
}

validation () {
read -r -p "Are you sure? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
       sleep 1
        ;;
    *)
        exit
        ;;
esac
}

debian8_prep() {
echo " Upgrade the system"
apt-get update && apt-get -y upgrade
echo "Virtualization host installation"
apt-get -y install qemu-kvm libvirt-dev virtinst virt-viewer libguestfs-tools virt-manager uuid-runtime curl linux-source libosinfo-bin genisoimage
#echo "kcli libvirt  wrapper installation"
#apt-get -y install python-pip pkg-config libvirt-dev genisoimage qemu-kvm netcat libvirt-bin python-dev libyaml-dev
#pip install kcli
source /etc/os-release
if [ "$ID" == "ubuntu" ] && [ "$VERSION_ID" == "20.04" ] ; then
apt-get -y install libvirt-daemon-system dnsmasq
fi
echo "Enabling Nested Virtualization"
rmmod kvm-intel
sh -c "echo 'options kvm-intel nested=y' >> /etc/modprobe.d/dist.conf"
modprobe kvm-intel
cat /sys/module/kvm_intel/parameters/nested
if [ -f /etc/ubuntu-advantage ]; then
apt -y install apparmor-profiles
fi
}

centos7_prep() {
echo " Upgrade the system"
yum -y install epel-release
yum -y upgrade
echo "Virtualization host installation"
yum -y group install "Virtualization Host"
yum -y install @virt
yum -y install virt-manager virt-install qemu-kvm xauth virt-top libguestfs-tools virt-viewer virt-manager curl
#echo "kcli libvirt  wrapper installation"
yum -y install gcc libvirt-devel python3-devel genisoimage qemu-kvm nmap-ncat python3-pip
#pip install kcli
echo "Enabling Nested Virtualization"
rmmod kvm-intel
sh -c "echo 'options kvm-intel nested=y' >> /etc/modprobe.d/dist.conf"
modprobe kvm-intel
cat /sys/module/kvm_intel/parameters/nested
}

services_activation() {
echo "Activate all those services"
#systemctl stop firewalld
systemctl restart libvirtd
virt-host-validate
}

check_apache () {
yum install -y httpd curl || apt-get -y install apache2 curl
#We do so despite it being disabled
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
systemctl enable httpd || systemctl enable apache2
systemctl start httpd || systemctl start apache2
mkdir -p /var/www/html/conf
echo "this is ok" > /var/www/html/conf/ok
local check_value="this is ok"
local check_remote=$(curl -s http://127.0.0.1/conf/ok)
if [ "$check_remote" = "$check_value" ] ; then
 echo "Apache is working"
else
 echo "Apache is not working"
 exit
fi
}

if [ "$EUID" -ne 0 ] ; then echo "Please run as root" ; exit ; fi
echo "This script will install all the necessary packages to use Libvirtd/KVM"
echo "Please reboot your host after this step"
if [ "$1" != "--force" ] ; then validation ; fi
check_distribution
services_activation
check_apache
echo "Please verify the install report et reboot your host"
