#!/bin/bash
# This script set vcpus count
guest=$1
vcpu=$2
parameters=$#

#confirm destroy

check_parameters () {
# Count and check parmaters given
if [ "$parameters" -ne 2  ] ; then
echo "Description : This script set vcpus count"
echo "Usage       : $0 <guest name> <size in MB>"
echo "Example     : '$0 guest1 2' set 2 vcpus"
exit
fi
# Check if the guest name is a defined guest
guests_defined="$(virsh list --all --name)"
if grep -qvw "$guest" <<< ${guests_defined}  ; then
echo "Please provide a live guest name : exit"
echo "Guests available :"
echo "$(virsh list --name)"
exit
fi
if [ "$vcpu" -lt 1 ] ; then
echo "Please provide minimum 1 vcpu count"
exit
fi
if [ "$vcpu" -gt 4 ] ; then
echo "Please provide minimum 4 vcpus count"
exit
fi
}

add_vcpus () {
virsh destroy $guest
virsh setvcpus $guest $vcpu --config --maximum
virsh setvcpus $guest $vcpu --config
virsh start $guest
virsh dominfo $guest | grep "CPU(s)"
}

check_parameters
add_vcpus
