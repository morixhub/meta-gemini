#!/bin/bash

# Kill service ifplugd (that, under some circumstances, can delay the system halt)
systemctl kill --signal=SIGKILL ifplugd.service

# Launch /app/stop-ui.sh, if any
if [ -x /app/stop-ui.sh ]; then
    mkdir -p /var/run ;
    echo "Stopping app-ui..." >> /var/run/app-shutdown-ui.log ;

    # Wait for Weston to be available
    SERVICE_NAME="weston.service" ;
    echo "Checking $SERVICE_NAME availability..." >> /var/run/app-shutdown-ui.log ;

    # Check if the service is enabled
    EN=$(systemctl is-enabled "$SERVICE_NAME") ;

    if [[ $EN != "enabled" ]]; then

        # Log
        echo "$SERVICE_NAME is not enabled: giving-up with app-ui stop" >> /var/run/app-shutdown-ui.log ;

    else
        
        # Perform actual app stop
        /app/stop-ui.sh > /var/run/app-shutdown-ui.log 2>&1 &

    fi
fi

# Launch /app/stop.sh, if any
if [ -x /app/stop.sh ]; then
    mkdir -p /var/run ;
    echo "Stopping app..." >> /var/run/app-shutdown.log ;
    /app/stop.sh > /var/run/app-shutdown.log 2>&1 &
fi

# Lazy-umount boot, var and data (for avoiding troubles with system shutdown)
sync
umount -l /boot
umount -l /data
umount -l /var
