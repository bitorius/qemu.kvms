#!/bin/bash
VM=$1
#cp Fedora-Cloud-Base-37-1.7.x86_64.qcow2 $VM.qcow2
#qemu-img resize $VM.qcow2 20G
virt-install --connect qemu:///system --virt-type kvm --memory 4096 --name $VM --vcpus 2 --disk=size=30,backing_store="/m1/var/lib/libvirt/base_images/Fedora-Cloud-Base-37-1.7.x86_64.qcow2" --os-variant detect=on,name=fedora-unknown --network type=direct,source=eno1,source.mode=bridge --network network=isolated --noreboot --cloud-init user-data="$PWD/user-data" --noautoconsole
