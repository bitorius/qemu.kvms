#!/bin/bash
usage() { echo "Usage: $0 [-r y|n] [-l MAX_VMS]" 1>&2; exit 1; }


while getopts "r:l:" o; do
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
	l)
	    l=${OPTARG}
	    re='^[0-9]+$'
	    if ! [[ $l =~ $re ]] ; then
		echo "error: Not a number" >&2;
		usage
		exit 1
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

#Setting up bridge for intra-vm

echo "Setting up bridge on subnet 172.20.0.1/16"
sudo ip addr add 172.20.0.1/16 dev kvmBr0
sudo ip link set kvmBr0 up

echo "Running DNSMASQ for intra-vm dhcp"
sudo dnsmasq --interface=kvmBr0 --bind-interfaces --dhcp-range=172.20.0.2,172.20.255.254

VMCOUNT=0 #Current VMs created/start


echo  "$MY_MACHINE_LIST" | while read line ;
do
    if [ "$VMCOUNT" -ge "$l" ]; then
	echo "Exiting at $VMCOUNT VMs."
	exit -1;
    fi
    echo "$line"
    echo "===================================================="

    MAC_ADD_1=$(echo "$line" | awk -F, '{print $1}' | tr -d '"')
    MAC_ADD_2=$(echo "$line" | awk -F, '{print $2}' | tr -d '"')
    MAC_IF_1=vtp.$(echo $MAC_ADD_1| cut  -d ':' -f 5,6 | tr ":" ".")
    NAME=$(echo "$line" | awk -F, '{print $3}')
    CLUSTER=$(echo "$line" | awk -F, '{print $4}')
    
    echo MAC Address: $MAC_ADD_1
    echo MAC IF: $MAC_IF_1
    echo MAC Address 2: $MAC_ADD_2
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

    VMCOUNT=$((VMCOUNT+1))
    if [[ $RUN == "n" ]]; then
	RUN_CMD="echo -n"
    fi
    
    echo "Setting up vtap to WAN"
    echo "Adding link $MAC_IF_1"
    sudo ip link add link eno1 name $MAC_IF_1 type macvtap
    echo "Bringing Link $MAC_IF_1 up for $MAC_ADD_1"
    sudo ip link set $MAC_IF_1 address $MAC_ADD_1 up
    echo "Setting ownership on /sys/class/net/$MAC_IF_1/ifindex"
    sleep 2
    echo sudo chown $(whoami) /dev/tap$(cat /sys/class/net/$MAC_IF_1/ifindex)
    sudo chown $(whoami) /dev/tap$(cat /sys/class/net/$MAC_IF_1/ifindex)
    sleep 2

    echo "$MAC_IF_1 is setup for WAN communication through macvtap"
    echo "$MAC_ADD_2 is setup for intra-VM communication using kvmBr0"
    

    echo Running KVM 
    echo "kvm --name fcloud37_$NAME -m 1024 -hda $HDA_DIR/$HDA -cdrom cloud-init/seedci.$NAME.iso -chardev socket,id=compat_monitor1,path=qmp.$NAME.sock,server=on,wait=off -mon mode=control,chardev=compat_monitor1 -net nic,id=n1,netdev=t1,model=virtio,macaddr=$(cat /sys/class/net/$MAC_IF_1/address) -netdev tap,fd=3,id=t1 3<>/dev/tap$(cat /sys/class/net/$MAC_IF_1/ifindex) -nic bridge,br=kvmBr0,mac=$MAC_ADD_2"
    $RUN_CMD kvm --name fcloud37_$NAME -m 8000 -hda $HDA_DIR/$HDA -cdrom cloud-init/seedci.$NAME.iso -chardev socket,id=compat_monitor1,path=qmp.$NAME.sock,server=on,wait=off -mon mode=control,chardev=compat_monitor1 -net nic,id=n1,netdev=t1,model=virtio,macaddr=$(cat /sys/class/net/$MAC_IF_1/address) -netdev tap,fd=3,id=t1 3<>/dev/tap$(cat /sys/class/net/$MAC_IF_1/ifindex) -nic bridge,br=kvmBr0,mac=$MAC_ADD_2 -vnc :$((NAME+10)) &

    if [[ $RUN == "y" ]];then
	sleep 1
	echo '{ "execute": "qmp_capabilities" }{ "execute": "query-status" }' cat && echo socat UNIX:$PWD/qmp.$NAME.sock stdio
	echo Waiting for next vm
	sleep 5
    fi
done
