#!/bin/bash

# Locate boot device
# (it is necessary because the boot device changes booting from uSD or eMMC)
BOOT_DEVICE=`cat /proc/cmdline | sed -e 's/^.*root=//' -e 's/ .*$//' | sed 's/..$//'`

# Expose boot device as USB mass storage gadget
modprobe g_mass_storage file=${BOOT_DEVICE} stall=0 removable=1 ro=1 iManufacturer="Aesys" iProduct="Aesys Mass Storage Gadget"

# Launch /app/start.sh, if any
if [ -x /app/start.sh ]; then
    mkdir -p /var/run ;
    echo "Starting app..." >> /var/run/app-startup.log ;
    /app/start.sh > /var/run/app-startup.log 2>&1 &
fi

# Launch /app/start-ui.sh, if any
if [ -x /app/start-ui.sh ]; then
    mkdir -p /var/run ;
    echo "Starting app-ui..." >> /var/run/app-startup-ui.log ;

    # Wait for weston to be available
    SERVICE_NAME="weston.service" ;
    echo "Waiting $SERVICE_NAME to be ready..." >> /var/run/app-startup-ui.log ;

    # Check if the service is enabled
    EN=$(systemctl is-enabled "$SERVICE_NAME") ;

    if [[ $EN != "enabled" ]]; then

        # Log
        echo "$SERVICE_NAME is not enabled: giving-up with app-ui start" >> /var/run/app-startup-ui.log ;

    else

        while true; do
            # Check if the service is running
            STATE=$(systemctl show -p SubState "$SERVICE_NAME" | cut -d'=' -f2) ;

            # Dump current weston status
            echo "$SERVICE_NAME state: $STATE" >> /var/run/app-startup-ui.log ;

            if [[ "$STATE" == "running" ]]; then
                    echo "$SERVICE_NAME is ready: going ahead with application start..." >> /var/run/app-startup-ui.log ;
                    break ;
            fi

            # Take breath
            sleep 1 ;
        done ;

        # Ensure XDG runtime directory is set
        if [ -z "$XDG_RUNTIME_DIR" ]; then
            export XDG_RUNTIME_DIR=/run/user/`id -u` ;
            if [ ! -d "$XDG_RUNTIME_DIR" ]; then
                mkdir -p "$XDG_RUNTIME_DIR" ;
                chmod 700 "$XDG_RUNTIME_DIR" ;
            fi
        fi

        # Wait for weston session (ATTENTION: keep wildcard out of quotes!)
        SESSION=$(ls -1 "$XDG_RUNTIME_DIR/wayland-"? | head -n 1) ;
        while [ ! -e "$SESSION" ]; do

            # Dump
            echo "Waiting $SERVICE_NAME session at $XDG_RUNTIME_DIR..." >> /var/run/app-startup-ui.log ;

            # Take breath
            sleep 1 ;

            # Try again
            SESSION=$(ls -1 "$XDG_RUNTIME_DIR/wayland-"? | head -n 1) ;

        done ;

        # Set display (ATTENTION: keep wildcard out of quotes!)
        DISPLAY=$(ls -1 "/run/wayland-"? | head -n 1) ;
        while [ ! -e "$DISPLAY" ]; do

            # Dump
            echo "Waiting $SERVICE_NAME session at $XDG_RUNTIME_DIR..." >> /var/run/app-startup-ui.log ;

            # Take breath
            sleep 1 ;

            # Try again
            DISPLAY=$(ls -1 "/run/wayland-"? | head -n 1) ;

        done ;
        export WAYLAND_DISPLAY="$DISPLAY" ;

        # Perform actual app start
        /app/start-ui.sh >> /var/run/app-startup-ui.log ;
    fi
fi
