#!/bin/bash

function prepare_if() {
    # Get interface
    IFACE="$1" ;

    MODE= ;
    if [ -f "/data/.sys/dhcpcd/mode_${IFACE}" ]; then
        MODE=$(cat "/data/.sys/dhcpcd/mode_${IFACE}") ;
    fi

    FOUND=0 ;
    if [ $FOUND -eq 0 ]; then
        if [ "${MODE}" == "last" ] || [ "${MODE}" == "last-or-static" ]; then
            if [ -f "/data/.sys/dhcpcd/last_${IFACE}" ]; then
                echo >> /etc/dhcpcd.conf ;
                echo "profile fallback_profile_${IFACE}" >> /etc/dhcpcd.conf ;
                cat "/data/.sys/dhcpcd/last_${IFACE}" >> /etc/dhcpcd.conf ;

                FOUND=1 ;
            fi
        fi
    fi

    if [ $FOUND -eq 0 ]; then
        if [ "${MODE}" == "static" ] || [ "${MODE}" == "last-or-static" ]; then
            if [ -f "/data/.sys/dhcpcd/static_${IFACE}" ]; then
                echo >> /etc/dhcpcd.conf ;
                echo "profile fallback_profile_${IFACE}" >> /etc/dhcpcd.conf ;
                cat "/data/.sys/dhcpcd/static_${IFACE}" >> /etc/dhcpcd.conf ;

                FOUND=1 ;
            fi
        fi
    fi

    if [ $FOUND -eq 1 ]; then
        echo >> /etc/dhcpcd.conf ;
        echo "interface ${IFACE}" >> /etc/dhcpcd.conf ;
        echo "fallback fallback_profile_${IFACE}" >> /etc/dhcpcd.conf ;
    fi
}

# Cut-off the "dynamic" portion of dhcpcd.conf
sed -i -z 's/#-----\n.*/#-----\n/' /etc/dhcpcd.conf

# Process interfaces
prepare_if "wired0"
prepare_if "wired1"
prepare_if "mlan0"

# Write processing info
echo >> /etc/dhcpcd.conf
echo "# Last refreshed on $(date)" >> /etc/dhcpcd.conf
