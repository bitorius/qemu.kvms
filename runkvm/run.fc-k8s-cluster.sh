#!/bin/bash
KVM_DIR="fc-k8s-cluster"
IMAGE=Fedora-Cloud-Base-37-1.7.x86_64.qcow2
HDA_DIR=hda

#Get all machines we should be running
pushd .
cd ../go-genmac
MY_MACHINE_LIST=$(./getVMInfo.sh fc-k8s-cluster)
MY_MACHINE_COUNT=$(echo "$MY_MACHINE_LIST"| wc -l)
echo "Creating $MY_MACHINE_COUNT machines"
popd

mkdir -pv $KVM_DIR
cd $KVM_DIR
pwd

mkdir -pv $HDA_DIR

echo  "$MY_MACHINE_LIST" | while read line ;
do
    echo "$line"
    echo "===================================================="

    MAC_ADD=$(echo "$line" | awk -F, '{print $1}')
    NAME=$(echo "$line" | awk -F, '{print $2}')
    CLUSTER=$(echo "$line" | awk -F, '{print $3}')
    
    echo MAC Address: $MAC_ADD
    echo Name: $NAME
    echo Cluster: $CLUSTER
    HDA=$(basename $IMAGE|sed 's/\.[^.]*$//').$NAME.qcow2
    if [ -f "$HDA_DIR/$HDA" ]; then
	echo "Existing drive found for $HDA_DIR/$HDA"
    else
	IMAGE_BASE=../../base_images
	cp $IMAGE_BASE/$IMAGE $HDA_DIR/$HDA -v
	echo "Default image is $(du -sh $IMAGE_BASE/$IMAGE)"
	qemu-img resize $HDA_DIR/$HDA 20G
	echo "New image is $(du -sh $HDA_DIR/$HDA)"
	echo "Generating seedci.$NAME.iso"
	cd cloud-init
	./create_cidata.sh $NAME
	cd ..
    fi
    kvm --name fcloud37_$NAME -m 1024 -hda $HDA_DIR/$HDA -cdrom cloud-init/seedci.$NAME.iso -chardev socket,id=compat_monitor1,path=qmp.$NAME.sock,server=on,wait=off -mon mode=control,chardev=compat_monitor1 -vnc :$NAME &
    sleep 1
    echo '{ "execute": "qmp_capabilities" }{ "execute": "query-status" }' | socat UNIX:$PWD/qmp.$NAME.sock stdio
#	kvm --name fcloud37_$NAME -m 1024 -hda $HDA_DIR/$HDA -cdrom cloud-init/seedci.$NAME.iso -vnc :$NAME &
done
