#!/bin/bash
# For educational purposes : http://linux.goffinet.org/
# This script create a L3 bridge for hetzner IPv4 public ranges
name="${1}"
bridge="$name"
type="${2}"
parameters="$#"
path="/tmp"

error () {
echo "Description : This script create a L3 bridge to forward Hetzner IPv4 public ranges to your VMs"
echo "Syntax      : '$0 <name> <ip4|ip4_dhcp> <ipv4 network> <ipv4 netmask> <ipv4 gateway>'"
echo "              <ivp4 gateway> is the ipv4 address of the enp2s0 interface"
echo "Examples    : '$0 hetzner1 ip4 5.9.214.208 255.255.255.248 5.9.156.152'"
echo "              '$0 hetzner1 ip4_dhcp 5.9.214.208 255.255.255.248 5.9.156.152'"
exit
}

if [ "$parameters" -eq 0 ] ; then
error
# check and fix IPv4 parameters
elif [[ "$type" == "ip4" || "$type" == "ip4_dhcp" ]] ; then
declare ip4_network="${3}"
declare ip4_netmask="${4}"
declare ip4_gateway="${5}"
declare interface=$(ip -4 a | grep -B 1 "${ip4_gateway}" | head -1 | cut -d ":" -f 2)
IFS=. read -r i1 i2 i3 i4 <<< "$ip4_network"
IFS=. read -r m1 m2 m3 m4 <<< "$ip4_netmask"
declare ip4_router_address="$((i1 & m1 | 255-m1)).$((i2 & m2 | 255-m2)).$((i3 & m3 | 255-m3)).$(((i4 & m4 | 255-m4)-1))"
declare ip4_first_address="$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$(((i4 & m4)+1))"
else
error
fi

ip4 () {
# Create a routed bridge xml file for IPv4 (NAT) without dhcp
cat << EOF > ${path}/${name}.xml
<network>
  <name>${name}</name>
  <forward mode="route"/>
    <interface dev="${interface// /}"/>
  <bridge name="${bridge}" stp="off"/>
  <ip address="${ip4_router_address}" netmask="${ip4_netmask}">
  </ip>
</network>
EOF

}

ip4_dhcp () {
# Create a routed bridge xml file for IPv4 with dhcp
cat << EOF > ${path}/${name}.xml
<network>
  <name>${name}</name>
  <forward mode="route"/>
    <interface dev="${interface// /}"/>
  <bridge name="${bridge}" stp="off"/>
  <ip address="${ip4_router_address}" netmask="${ip4_netmask}">
    <dhcp>
      <range start="${ip4_first_address}" end="${ip4_router_address}"/>
    </dhcp>
  </ip>
</network>
EOF
}

ip4_report () {
cat << EOF > ~/${name}_report.txt
Bridge Name         : $name
------------------------------------------------------------
Bridge IPv4 address : ${ip4_router_address}
IPv4 range          : ${ip4_first_address} - ${ip4_router_address}
EOF
echo "~/${name}_report.txt writed : "
cat ~/${name}_report.txt
}

check_type () {
# Check if the bridge type paramter given is "isolated" or "nat"
case "${type}" in
    ip4) ip4 ; ip4_report ;;
    ip4_dhcp) ip4_dhcp ; ip4_report ;;
    *) echo "ip4 or ip4_dhcp ?" ; error ;;
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

check_type
create_bridge
