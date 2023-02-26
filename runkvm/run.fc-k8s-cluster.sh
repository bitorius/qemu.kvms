#!/bin/bash
usage() { echo "Usage: $0 [-r y|n] " 1>&2; exit 1; }


while getopts "r:" o; do
    case "${o}" in
        r)
            r=${OPTARG}
            if [[ $r == "y" || $r == "n" ]]
	    then
		RUN=$r
	    else
		echo "That option is not valid for -$o"
		usage
		exit -1
	    fi
            ;;
	? )
	    echo  "Please provide a valid option"
	    usage
	    exit -1
	    ;;
	:)
	    echo ":"
	    usage
	    exit -1
	    ;;
	*)
	    echo "*"
	    usage
	    exit -1
	    ;;
	
	
	esac
done

if [ $# -eq 0 ]
  then
      echo "No arguments supplied"
      usage
fi


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
    MAC_IF=vtp$(echo $MAC_ADD| cut  -d ':' -f 5,6 | tr ":" ".")
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

    if [[ $RUN == "y" ]]; then
	sudo ip link add link eno1 name $MAC_IF type macvtap
	sudo ip link set $MAC_IF address $MAC_ADD up
	sudo chown $(whoami) /dev/tap$(cat /sys/class/net/$MAC_IF/ifindex)
	sleep 5
	kvm --name fcloud37_$NAME -m 1024 -hda $HDA_DIR/$HDA -cdrom cloud-init/seedci.$NAME.iso -chardev socket,id=compat_monitor1,path=qmp.$NAME.sock,server=on,wait=off -mon mode=control,chardev=compat_monitor1 -net nic,model=virtio,macaddr=$(cat /sys/class/net/$MAC_IF/address) -net tap,fd=3 3<>/dev/tap$(cat /sys/class/net/$MAC_IF/ifindex) -vnc :$NAME &
	sleep 1
	echo '{ "execute": "qmp_capabilities" }{ "execute": "query-status" }' | socat UNIX:$PWD/qmp.$NAME.sock stdio
    else
	echo "sudo ip link add link eno1 name $MAC_IF type macvtap"
	echo "sudo ip link set $MAC_IF address $MAC_ADD up"
	echo "sudo chown $(whoami) /dev/tap$(cat /sys/class/net/$MAC_IF/ifindex)"
	echo "kvm --name fcloud37_$NAME -m 1024 -hda $HDA_DIR/$HDA -cdrom cloud-init/seedci.$NAME.iso -chardev socket,id=compat_monitor1,path=qmp.$NAME.sock,server=on,wait=off -mon mode=control,chardev=compat_monitor1 -net nic,model=virtio,macaddr=$(cat /sys/class/net/$MAC_IF/address) -net tap,fd=3 3<>/dev/tap$(cat /sys/class/net/$MAC_IF/ifindex) -vnc :$NAME &"
    fi
done
