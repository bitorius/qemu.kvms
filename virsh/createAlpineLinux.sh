virt-install --connect qemu:///system -n something --vnc --vnclisten=0.0.0.0 --os-type=linux --virt-type kvm --memory 4096 --network type=direct,source=eth2,source.mode=bridge --disk virtd/alpine-extended-3.13.2-x86_64.iso --disk virtd/vm-100-disk-0.qcow2  --o
sinfo alpinelinux3.13 --import
