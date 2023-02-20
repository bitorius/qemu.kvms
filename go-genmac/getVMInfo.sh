#!/bin/bash
vmappident=$1
if [ -z "$vmappident" ]
then
	echo "VM app identifer required!"
	exit -1
else
	echo -e ".mode csv \n select vm_mac,vm_name,vm_appident from virtmach where vm_appident='$vmappident';" | sqlite3 kvms.sqlite
exit -1
fi
