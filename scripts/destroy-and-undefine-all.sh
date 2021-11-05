#!/bin/bash
#This script destroy, undefine and remove storage for all the guests

destroy_all () {
for x in $(virsh list --all --name); do virsh destroy $x; virsh undefine $x --remove-all-storage; done
}

main () {
echo "This script destroy, undefine and remove storage for all the guests"
read -r -p "Are you sure? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY]) 
        destroy_all
        ;;
    *)
        exit 
        ;;
esac
}

#main
destroy_all
