#!/bin/bash
# For educational purposes : http://linux.goffinet.org/
# This script create an isolated, a simple nat without dhcp 
# or  a nat/ipv6 bridge <name> <type>
name=${1}
bridge=$name
# 'isolated' or 'nat'
type=${2}
parameters=$#
path="/tmp"
net_id1="$(shuf -i 0-255 -n 1)"
net_id2="$(shuf -i 0-255 -n 1)"
# random /24 in 10.0.0.0/8 range
ip4="10.${net_id1}.${net_id2}."
ip6="fd00:${net_id1}:${net_id2}::"
# Fix your own range
#ip4="192.168.1."
#ip6="fd00:1::"

check_parameters () {
# Check the number of parameters given and display help
if [ "$parameters" -ne 2  ] ; then
echo "Description : This script create an isolated, nat or full bridge" 
echo "Usage       : $0 <name> <type : isolated or nat or full>"
echo "Example     : '$0 net1 isolated' or '$0 lan101 nat'"
exit
fi
}

check_bridge_interface () {
# Check if the bridge interface name given is in use and display help
if [ -e /run/libvirt/network/${name}.xml ] ; then
echo "This bridge name ${name} is already in use"
echo "Change the bridge name or do 'virsh net-destroy ${name}' : exit"
exit
fi
}

check_interface () {
# Check if the bridge name is present
if [ -z "${bridge}" ]; then
echo "Please provide a valid interface name : exit"
exit
fi
# Check if the bridge interface is in use and display help
intlist=$(echo $(ls /sys/class/net))
for interface in ${intlist} ; do
if [ ${interface} = ${bridge} ] ; then
echo "This interface ${bridge} is already in use"
echo "Please provide an other bridged interface name : exit"
exit
fi
done
}

validate_ip_range () {
# Function to valide chosen IP prefixes

check_ip4 () {
# Check if the IPv4 prefix computed is in use
ip4list=$(echo $(ip -4 route | awk '{ print $1; }' | sed 's/\/.*$//'))
for ip4int in ${ip4list} ; do
if [ ${ip4int} = ${ip4} ] ; then
echo "Random Error, Please retry $@ : exit"
exit
fi
done
}

check_ip6 () {
# Check if the IPv6 prefix is in use
ip6list=$(echo $(ip -6 route | awk '{ print $1; }' | sed 's/\/.*$//'))
for ip6int in ${ip6list} ; do
if [ ${ip6int} = ${ip6} ] ; then
echo "Random Error, Please retry $@ : exit"
exit
fi
done
}

check_ip4
check_ip6
}

isolated () {
# Create a simple bridge xml file
cat << EOF > ${path}/${name}.xml
<network>
  <name>${name}</name>
  <bridge name='${bridge}' stp='on' delay='0'/>
</network>
EOF
}

nat () {
# Create a routed bridge xml file for IPv4 (NAT) without dhcp
cat << EOF > ${path}/${name}.xml
<network>
  <name>${name}</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='${bridge}' stp='on' delay='0'/>
  <domain name='${name}'/>
  <ip address='${ip4}1' netmask='255.255.255.0'>
  </ip>
</network>
EOF
}

report_nat () {
# Reporting Function about IPv4 and IPv6 configuration
cat << EOF > ~/${name}_report.txt
Bridge Name         : $name
Bridge Interface    : $bridge
------------------------------------------------------------
Bridge IPv4 address : ${ip4}1/24
IPv4 range          : ${ip4}0 255.255.255.0
DNS Servers         : ${ip4}1 and ${ip6}1
EOF
echo "~/${name}_report.txt writed : "
cat ~/${name}_report.txt
}

nat_ipv6 () {
# Create a routed bridge xml file for IPv4 (NAT) and IPv6 private ranges
cat << EOF > ${path}/${name}.xml
<network ipv6='yes'>
  <name>${name}</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='${bridge}' stp='on' delay='0'/>
  <domain name='${name}'/>
  <ip address='${ip4}1' netmask='255.255.255.0'>
    <dhcp>
      <range start='${ip4}128' end='${ip4}150'/>
    </dhcp>
  </ip>
  <ip family='ipv6' address='${ip6}1' prefix='64'>
    <dhcp>
      <range start='${ip6}100' end='${ip6}1ff'/>
    </dhcp>
  </ip>
</network>
EOF
}

report_nat_ipv6 () {
# Reporting Function about IPv4 and IPv6 configuration
cat << EOF > ~/${name}_report.txt
Bridge Name         : $name
Bridge Interface    : $bridge
------------------------------------------------------------
Bridge IPv4 address : ${ip4}1/24
IPv4 range          : ${ip4}0 255.255.255.0
DHCP range          : ${ip4}128 - ${ip4}150
Bridge IPv6 address : ${ip6}1/64
IPv6 range          : ${ip6}/64
DHCPv6 range        : ${ip6}128/64 - ${ip6}150/64
DNS Servers         : ${ip4}1 and ${ip6}1
EOF
echo "~/${name}_report.txt writed : "
cat ~/${name}_report.txt
}

check_type () {
# Check if the bridge type paramter given is 'isolated' or 'nat'
case ${type} in
    isolated) isolated ;;
    nat) nat ; report_nat ;;
    full) nat_ipv6 ; report_nat_ipv6 ;;
    *) echo "isolated, nat or full ? exit" ; exit ;;
esac
}

create_bridge () {
# Bridge creation
#cat ${path}/${name}.xml
virsh net-destroy ${name} 2> /dev/null
virsh net-undefine ${name} 2> /dev/null
virsh net-define ${path}/${name}.xml
virsh net-autostart ${name}
virsh net-start ${name}
virsh net-list
}

check_parameters
validate_ip_range
check_interface
check_bridge_interface
check_type
create_bridge
