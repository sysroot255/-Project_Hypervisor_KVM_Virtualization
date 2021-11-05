#!/bin/bash
# For educational purposes : http://linux.goffinet.org/
# This script create a L2 bridge that connects a physical NIC
name=${1}
bridge=$name
interface=${2}
parameters=$#
path="/tmp"

check_parameters () {
# Check the number of parameters given and display help
if [ "$parameters" -eq 0  ] ; then
echo "Description : This script create a L2 bridge that connects a physical NIC"
echo "Usage       : $0 <name> <interface name>"
echo "Example     : '$0 internet enp2s0'"
exit
fi
}

check_bridge () {
# Check if the bridge interface name given is in use and display help
if [ -e /run/libvirt/network/${name}.xml ] ; then
echo "This bridge name ${name} is already in use"
echo "Change the bridge name or do 'virsh net-destroy ${name}' : exit"
exit
fi
}

bridged () {
cat << EOF > ${path}/${name}.xml
<network>
  <name>${name}</name>
  <forward mode="bridge">
    <interface dev="${interface}"/>
  </forward>
</network>
EOF
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
check_bridge
bridged
create_bridge
