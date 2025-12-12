#!/bin/bash

# Disable HW watchdog
if [ -x /usr/bin/hw-wdog-toggle.sh ]; then
    bash -c "/usr/bin/hw-wdog-toggle.sh disable" ;
fi

# Extract the netboot server IP
NETBOOT_SERVER_IP=$(mount | grep -i "on / " | cut -d':' -f1)

if [ -z "$NETBOOT_SERVER_IP" ]; then
    exit 1;
fi

# Infinite loop
while true
do
    # Check if the the netboot tools export is mounted
    MNT=$(mount | grep -i "on /run/netboot/tools ") ;
    if [ -z "$MNT" ]; then
        # If there the mount is not there; so prepare the directory, if requested...
        if [ ! -d "/run/netboot/tools" ]; then
            mkdir -p "/run/netboot/tools" ;
        fi

        # ...and attempt to mount the export via netboot server's NFS
        mount -t nfs "$NETBOOT_SERVER_IP:/mnt/data/netboot/tools" "/run/netboot/tools" ;
    fi

    # Get HW/IP address from wired0
    HW_ADDR=$(ifconfig wired0 | grep "ether " | awk ' { print $2 } ')
    IP_ADDR=$(ifconfig wired0 | grep "inet " | awk ' { print $2 } ')

    # If not available, then attempt to use wired1
    if [ -z "$HW_ADDR" ] || [ -z "$IP_ADDR" ]; then
        HW_ADDR=$(ifconfig wired1 | grep "ether " | awk ' { print $2 } ')
        IP_ADDR=$(ifconfig wired1 | grep "inet " | awk ' { print $2 } ')
    fi

    # Raise the device hand! :)
    if [ ! -z "$HW_ADDR" ] && [ ! -z "$IP_ADDR" ]; then
        curl -X "POST" "http://$NETBOOT_SERVER_IP:5000/deviceRaiseHand" -H "accept: */*" -H "Content-Type: application/json" -d '{ "mac": "'$HW_ADDR'", "ipAddress": "'$IP_ADDR'" }' ;
    fi

    # Take breath
    sleep 5 ;

done

