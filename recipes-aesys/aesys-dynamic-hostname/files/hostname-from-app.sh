#!/bin/bash

# Check app dynamic hostname availability
if [ ! -x "/app/dynamic-hostname.sh" ]; then

    # Log
    echo "Dynamic hostname script from app is not available: giving-up" ;
    exit 1 ;
fi

# Get dynamic hostname from app
HOSTNAME=$(/app/dynamic-hostname.sh 2>/dev/null);

if [ $? -ne 0 ] || [ -z "$HOSTNAME" ]; then
    
    # Log
    echo "Invalid dynamic hostname from app: giving-up" ;
    exit 2 ;
fi
	
# Log
echo "Setting hostname $HOSTNAME..." ;

# Set runtime hostname
echo "$HOSTNAME" > /proc/sys/kernel/hostname;

if [ $? -ne 0 ]; then
    echo "Cannot set runtime hostname" ;
    exit 3 ;
fi

# Some actions are performed only if RAM overlay is enabled
if [ -f /initram/overlayroot.enforced ]; then
    
    # Set static hostname
    echo "$HOSTNAME" > /etc/hostname;
    
    if [ $? -ne 0 ]; then
        echo "Cannot set static hostname" ;
        exit 4 ;
    fi
    
    # Update /etc/hosts, if requested
    CHECK=$(cat /etc/hosts | grep -i "127.0.0.1 $HOSTNAME") ;
    
    if [ -z "$CHECK" ]; then
        echo "127.0.0.1 $HOSTNAME" >> /etc/hosts;
    
        if [ $? -ne 0 ]; then
            echo "Cannot update /etc/hosts" ;
            exit 5 ;
        fi
    fi
fi

# Log
echo "Hostname set to $HOSTNAME";
