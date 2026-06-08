#!/bin/bash

usage () {
    cat << EOF
Usage: ${0##*/} [-h] [-d]

Tells the current status of the HW watchdog. The status is dumped on stdout and can be one of the following:
- "disabled": the HW watchdog is currenty disabled;
- "enabled": the HW watchdog is currently enabled.

OPTIONS:
-h  Displays this help and exit
-d  Provide details; the output format is: <MODE>:<STATUS> where:
    <MODE> can be either "forced" or "default";
    <STATUS> can be either "disabled" or "enabled".

RETURN VALUE:
    0: Success (no changes made)
    Other: Error code

EOF
}

# Process options
DETAILS=0
while getopts hd opt; do
    case $opt in
        h)
            usage ;
            exit 0 ;
            ;;
        d)
            DETAILS=1 ;
        ;;
        ?)
            echo >&2 ;
            usage >&2 ;
            exit 1;
            ;;
    esac
done

# GPIO5_25 is used for toggling WDOG
WD_GPIO=$(( ((5-1)*32)+25 ))

# Export GPIO if requested
if [ ! -d "/sys/class/gpio/gpio$WD_GPIO" ]; then
    echo $WD_GPIO > "/sys/class/gpio/export" ;
fi

# Check if export suceeded, by accessing direction
if [ -f "/sys/class/gpio/gpio$WD_GPIO/direction" ]; then
    DIR=$(cat "/sys/class/gpio/gpio$WD_GPIO/direction") ;
    VALUE=$(cat "/sys/class/gpio/gpio$WD_GPIO/value") ;

    # Determine mode
    MODE= ;
    if [ "$DIR" == "in" ]; then
        MODE="default" ;
    else
        MODE="forced" ;
    fi

    # Determine status
    STATUS= ;
    if [ "$VALUE" == "1" ]; then
        STATUS="enabled" ;
    else
        STATUS="disabled" ;
    fi

    # Provide result
    if [ $DETAILS -eq 1 ]; then
        echo "$MODE:$STATUS" ;
    else
        echo "$STATUS" ;
    fi
else
    exit 1;
fi




