#!/bin/bash

for i in `sudo virsh list | grep running | awk '{print $2}'` do
    sudo virsh shutdown $i
done
