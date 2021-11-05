#!/bin/bash
# This script add a new NIC on live guest to a bridge or interface

guest=$1
bridge=$2
mac=$3
model="virtio"
parameters=$#

error () {
echo "Description : This script add a new NIC on live guest to an interface"
echo "Usage       : '$0 <guest name> <bridge_interface_name> <macaddress>'"
echo "Example     : '$0 guest1 virbr0' add the live guest1 NIC to virbr0"
echo "              '$0 guest1 eth0' add the live guest1 NIC to eth0"
echo "              '$0 guest1 hetzner1 00:50:56:00:7F:E0' add the live guest1 NIC to bridged interface"

}

check_parameters () {
# Check the numbers of parameters required
if [ "$parameters" -gt 4  ] ; then
error
exit
elif [ "$parameters" -lt 2  ] ; then
error
exit
fi
# Check if the guest name chosen is in live and display help to choose
#guests_defined_live="$(virsh list --name)"
#if grep -qvw "$guest" <<< ${guests_defined_live}  ; then
#echo "Please provide a live guest name : exit"
#echo "Guests available :"
#echo "$(virsh list --name)"
#exit
#fi
# Check if the bridge exists
if [ -e /run/libvirt/network/${bridge}.xml ] ; then
interface=$(virsh net-dumpxml "${bridge}" | grep 'forward dev' | sed -n "s/^.*<forward dev='\(.*\)' .*$/\1/p")
# Check if the bridge is a l2 bridge
if grep -qw "$interface" <<< $(ls /sys/class/net) ; then
mode="bridged"
fi
# Check if the bridge interface is available
elif grep -qvw "$bridge" <<< $(ls /sys/class/net) ; then
echo "This interface ${bridge} is not available"
echo "Please create a valid bridge or choose between : "
echo $(ls /sys/class/net)
exit
fi
}

mac_address () {
if [[ ! -z "$mac" ]] ; then
mac_param=" --mac $mac"
else
random_mac=$(tr -dc a-f0-9 < /dev/urandom | head -c 10 | sed -r 's/(..)/\1:/g;s/:$//;s/^/02:/')
mac_param=" --mac $random_mac"
mac="$random_mac"
fi
}

attach_nic () {
# Detach and attach the guest nic to the live guest
#virsh detach-interface $guest --type $type --source $bridge--live --persistent $mac_param
if egrep -q "eth|ens|em" <<< $bridge ; then
ip link set $bridge promisc on
cat << EOF > /tmp/direct-$bridge-$guest.xml
<interface type='direct'>
  <source dev='$bridge' mode='bridge'/>
  <model type='virtio'/>
</interface>
EOF
virsh attach-device $guest /tmp/direct-$bridge-$guest.xml
elif [[ "$mode" == "bridged" ]] ; then
cat << EOF > /tmp/direct-$bridge-$guest.xml
<interface type="direct">
  <source dev="$interface" mode="bridge"/>
  <mac address="$mac"/>
  <model type="virtio"/>
</interface>
EOF
virsh attach-device $guest /tmp/direct-$bridge-$guest.xml
else
#virsh attach-interface --domain $guest --type $type --source $bridge --model $model --live --persistent $mac_param
cat << EOF > /tmp/bridge-$bridge-$guest.xml
<interface type="bridge">
  <source bridge="$bridge"/>
  <mac address="$mac"/>
  <model type="virtio"/>
</interface>
EOF
virsh attach-device $guest /tmp/bridge-$bridge-$guest.xml

fi
virsh domiflist $guest
}

check_parameters
mac_address
attach_nic
