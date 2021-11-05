#!/bin/bash
#Centos 7/8, Fedora 32, Debian Stable or Ubuntu 18.04 Bionic fully automatic installation by HTTP Repos and response file via local HTTP.
image="$1" # centos, fedora, debian, bionic
name="$2"
silent="$3"
bridge="virbr0"
bridgeip4="192.168.122.1"
country="fr"
fedora_version="32"
url_bionic_mirror="http://${country}.archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/"
url_debian_mirror="http://ftp.debian.org/debian/dists/stable/main/installer-amd64/"
url_centos7_mirror="http://mirror.centos.org/centos/7/os/x86_64/"
url_centos8_mirror="http://mirror.centos.org/centos/8/BaseOS/x86_64/kickstart/"
curl -V >/dev/null 2>&1 || { echo >&2 "Please install curl"; exit 2; }
url_fedora_mirror=$(curl -v --silent "https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-${fedora_version}&arch=x86_64&country=global" 2>&1 | grep 'dl.fedoraproject' | head -n 1)
#local_debian_iso=/var/lib/iso/debian-8.6.0-amd64-netinst.iso
#local_centos_iso=/var/lib/iso/CentOS-7-x86_64-DVD-1611.iso
bionic_mirror=$url_bionic_mirror
debian_mirror=$url_debian_mirror
centos7_mirror=$url_centos7_mirror
fedora_mirror=$url_fedora_mirror
centos8_mirror=$url_centos8_mirror
autoconsole=""
#autoconsole="--noautoconsole"
url_configuration="http://${bridgeip4}/conf/${image}-${name}.cfg"

usage () {
echo "Usage : $0 [ centos | centos8 | fedora | debian | bionic ] vm_name"
}

check_guest_name () {
if [ -z "${name}" ]; then
echo "Centos 7/8, Fedora 32, Debian Stable or Ubuntu 18.04 Bionic fully automatic installation by HTTP Repos and response file via local HTTP."
usage
echo "Please provide one distribution centos, centos8, fedora, debian, bionic and one guest name: exit"
exit
fi
if grep -qw "${name}" <<< $(virsh list --all --name)  ; then
usage
echo "Please provide a defined guest name that is not in use : exit"
exit
fi
if [ "${silent}" = "--silent" ] ; then
  autoconsole="--noautoconsole"
fi
}

check_apache () {
yum install -y httpd curl || apt-get install apache2 curl
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
systemctl enable httpd
systemctl start httpd
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

launch_guest () {
if ! grep -q 'vmx\|svm' /proc/cpuinfo ; then echo "Please enable virtualization instructions" ; exit 1 ; fi
{ grep -q 'vmx\|svm' /proc/cpuinfo ; [ $? == 0 ]; } || { echo "Please enable virtualization instructions" ; exit 1 ;  }
[ `grep -c 'vmx\|svm' /proc/cpuinfo` == 0 ] && { echo "Please enable virtualization instructions" ; exit 1 ;  }
virt-install -h >/dev/null 2>&1 || { echo >&2 "Please install libvirt"; exit 2; }
virt-install \
--virt-type=kvm \
--name=$name \
--disk path=/var/lib/libvirt/images/$name.qcow2,size=32,format=qcow2 \
--ram=$ram \
--vcpus=1 \
--os-variant=$os \
--network bridge=$bridge \
--graphics none \
--noreboot \
--console pty,target_type=serial \
--location $mirror \
-x "auto=true hostname=$name domain= $config text console=ttyS0 $autoconsole"
}

bionic_response_file () {
touch /var/www/html/conf/${image}-${name}.cfg
cat << EOF > /var/www/html/conf/${image}-${name}.cfg
d-i debian-installer/language                               string      en_US:en
d-i debian-installer/country                                string      US
d-i debian-installer/locale                                 string      en_US
d-i debian-installer/splash                                 boolean     false
d-i localechooser/supported-locales                         multiselect en_US.UTF-8
d-i pkgsel/install-language-support                         boolean     true
d-i console-setup/ask_detect                                boolean     false
d-i keyboard-configuration/modelcode                        string      pc105
d-i keyboard-configuration/layoutcode                       string      be
d-i debconf/language                                        string      en_US:en
d-i netcfg/choose_interface                                 select      auto
d-i netcfg/dhcp_timeout                                     string      5
d-i mirror/country                                          string      manual
d-i mirror/http/hostname                                    string      fr.archive.ubuntu.com
d-i mirror/http/directory                                   string      /ubuntu
d-i mirror/http/proxy                                       string
d-i time/zone                                               string      Europe/Paris
d-i clock-setup/utc                                         boolean     true
d-i clock-setup/ntp                                         boolean     false
d-i passwd/root-login                                       boolean     false
d-i passwd/make-user                                        boolean     true
d-i passwd/user-fullname                                    string      user
d-i passwd/username                                         string      user
d-i passwd/user-password                                    password    testtest
d-i passwd/user-password-again                              password    testtest
d-i user-setup/allow-password-weak                          boolean     true
d-i passwd/user-default-groups                              string      adm cdrom dialout lpadmin plugdev sambashare
d-i user-setup/encrypt-home                                 boolean     false
d-i apt-setup/restricted                                    boolean     true
d-i apt-setup/universe                                      boolean     true
d-i apt-setup/backports                                     boolean     true
d-i apt-setup/services-select                               multiselect security
d-i apt-setup/security_host                                 string      security.ubuntu.com
d-i apt-setup/security_path                                 string      /ubuntu
tasksel tasksel/first                                       multiselect openssh-server
d-i pkgsel/include                                          string      openssh-server python-simplejson vim
d-i pkgsel/upgrade                                          select      safe-upgrade
d-i pkgsel/update-policy                                    select      none
d-i pkgsel/updatedb                                         boolean     true
d-i partman/confirm_write_new_label                         boolean     true
d-i partman/choose_partition                                select      finish
d-i partman/confirm_nooverwrite                             boolean     true
d-i partman/confirm                                         boolean     true
d-i partman-auto/purge_lvm_from_device                      boolean     true
d-i partman-lvm/device_remove_lvm                           boolean     true
d-i partman-lvm/confirm                                     boolean     true
d-i partman-lvm/confirm_nooverwrite                         boolean     true
d-i partman-auto-lvm/no_boot                                boolean     true
d-i partman-md/device_remove_md                             boolean     true
d-i partman-md/confirm                                      boolean     true
d-i partman-md/confirm_nooverwrite                          boolean     true
d-i partman-auto/method                                     string      lvm
d-i partman-auto-lvm/guided_size                            string      max
d-i partman-partitioning/confirm_write_new_label            boolean     true
d-i grub-installer/only_debian                              boolean     true
d-i grub-installer/with_other_os                            boolean     true
d-i finish-install/reboot_in_progress                       note
d-i finish-install/keep-consoles                            boolean     false
d-i cdrom-detect/eject                                      boolean     true
d-i preseed/late_command in-target sed -i 's/PermitRootLogin\ prohibit-password/PermitRootLogin\ yes/' /etc/ssh/sshd_config ; in-target wget https://gist.githubusercontent.com/goffinet/f515fb4c87f510d74165780cec78d62c/raw/db89976e8c5028ce5502e272e49c3ed65bbaba8e/ubuntu-grub-console.sh ; in-target sh ubuntu-grub-console.sh ; in-target sed -i 's/ens2/eth0/' /etc/netplan/01-netcfg.yaml ; in-target shutdown -h now
EOF
}

debian_response_file () {
touch /var/www/html/conf/${image}-${name}.cfg
cat << EOF > /var/www/html/conf/${image}-${name}.cfg
d-i debian-installer/locale string en_US
d-i keyboard-configuration/xkb-keymap select be
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string unassigned-hostname
d-i netcfg/get_domain string unassigned-domain
d-i netcfg/wireless_wep string
d-i mirror/country string manual
d-i mirror/http/hostname string ftp.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string
d-i passwd/make-user boolean false
d-i passwd/root-password password testtest
d-i passwd/root-password-again password testtest
d-i clock-setup/utc boolean true
d-i time/zone string Europe/Paris
d-i clock-setup/ntp boolean true
d-i partman-auto/method string lvm
d-i partman-auto-lvm/guided_size string max
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
tasksel tasksel/first multiselect standard
d-i pkgsel/include string openssh-server vim
d-i pkgsel/upgrade select full-upgrade
popularity-contest popularity-contest/participate boolean false
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev  string /dev/vda
d-i finish-install/keep-consoles boolean true
d-i finish-install/reboot_in_progress note
d-i preseed/late_command string in-target sed -i 's/PermitRootLogin\ without-password/PermitRootLogin\ yes/' /etc/ssh/sshd_config ; in-target wget https://gist.githubusercontent.com/goffinet/f515fb4c87f510d74165780cec78d62c/raw/db89976e8c5028ce5502e272e49c3ed65bbaba8e/ubuntu-grub-console.sh ; in-target chmod +x ubuntu-grub-console.sh && sh ubuntu-grub-console.sh ; in-target shutdown -h now
EOF
}

redhat_response_file () {
read -r -d '' packages <<- EOM
@core
wget
EOM
touch /var/www/html/conf/${image}-${name}.cfg
cat << EOF > /var/www/html/conf/${image}-${name}.cfg
install
reboot
rootpw --plaintext testtest
keyboard --vckeymap=be-oss --xlayouts='be (oss)'
timezone Europe/Paris --isUtc
#timezone Europe/Brussels
lang en_US.UTF-8
#lang fr_BE
#cdrom
url --url="$mirror"
firewall --disabled
network --bootproto=dhcp --device=eth0
network --bootproto=dhcp --device=eth1
network --hostname=$name
# network --device=eth0 --bootproto=static --ip=192.168.22.10 --netmask 255.255.255.0 --gateway $bridgeip4 --nameserver=$bridgeip4 --ipv6 auto
#auth  --useshadow  --passalgo=sha512
text
firstboot --enable
skipx
ignoredisk --only-use=vda
bootloader --location=mbr --boot-drive=vda
zerombr
clearpart --all --initlabel
#autopart --type=thinp # See the bug resolved in 7.3 https://bugzilla.redhat.com/show_bug.cgi?id=1290755
autopart --type=lvm
#part /boot --fstype="xfs" --ondisk=vda --size=500
#part swap --recommended
#part pv.00 --fstype="lvmpv" --ondisk=vda --size=500 --grow
#volgroup local0 --pesize=4096 pv.00
#logvol /  --fstype="xfs"  --size=4000 --name=root --vgname=local0
%packages
$packages
%end
%post
yum -y update && yum -y upgrade
#mkdir /root/.ssh
#curl ${conf}/id_rsa.pub > /root/.ssh/authorized_keys
#sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/console=ttyS0"/console=ttyS0 net.ifnames=0 biosdevname=0"/' /etc/default/grub
grub2-mkconfig > /boot/grub2/grub.cfg
%end
EOF
}

configure_installation () {
case $image in
    centos)
        mirror=$centos7_mirror
        ram="2048" #requirement
        os="rhel7"
        config="ks=$url_configuration"
        redhat_response_file ;;
    centos7)
        mirror=$centos7_mirror
        ram="2048" #requirement
        os="rhel7"
        config="ks=$url_configuration"
        redhat_response_file ;;
    centos8)
        mirror=$centos8_mirror
        ram="2048" #requirement
        os="rhel7"
        config="ks=$url_configuration"
        redhat_response_file ;;
    fedora)
        mirror=$fedora_mirror
        ram="2048" #requirement
        os="rhel7"
        config="ks=$url_configuration"
        redhat_response_file ;;
    debian)
        mirror=$debian_mirror
        ram="1024"
        os="debianwheezy"
        config="url=$url_configuration"
        debian_response_file ;;
    bionic)
        mirror=$bionic_mirror
        ram="512"
        os="ubuntusaucy"
        config="url=$url_configuration"
        bionic_response_file ;;
    *)
        usage
        echo "Please provide one of those distributions" ;;
esac
}

check_guest_name
check_apache
configure_installation
launch_guest
