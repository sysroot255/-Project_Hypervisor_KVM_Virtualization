#!/bin/bash
# This script set RAM in MB
guest=$1
memory=$2
parameters=$#

#confirm destroy

check_parameters () {
# Count and check parmaters given
if [ "$parameters" -ne 2  ] ; then
echo "Description : This script set RAM in MB"
echo "Usage       : $0 <guest name> <size in MB>"
echo "Example     : '$0 guest1 1024' set RAM to 1024 MB"
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
if [ "$memory" -lt 128 ] ; then
echo "Please provide minimum 128 MB RAM"
exit
fi
}

add_memory () {
ram=$(virsh dommemstat $guest | grep actual | awk '{print $2}')
ramb=$(echo "$ram / 1024" | bc)
echo "Actual RAM in MB : $ramb"
virsh destroy $guest
virsh setmaxmem $guest ${memory}M --config
virsh setmem $guest ${memory}M --config
virsh start $guest
ram=$(virsh dommemstat $guest | grep actual | awk '{print $2}')
ramb=$(echo "$ram / 1024" | bc)
echo "Actual RAM in MB : $ramb"
}

check_parameters
add_memory
