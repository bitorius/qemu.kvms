#!/bin/bash
while true; do echo Listening; nc -l -4 192.168.254.1 9000 -w1 | tee -a vm_provision_log.txt; done
