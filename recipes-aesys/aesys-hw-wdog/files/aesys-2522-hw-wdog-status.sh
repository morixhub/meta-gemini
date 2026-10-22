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

# GPIO5_24 and GPIO 23 areis used for toggling WDOG
# Logic is:
# +------+------+---------------+
# | SET1 | SET0 | Status        |
# |  0   |  0   |  10 s         |
# |  0   |  1   |  (disabled)   |
# |  1   |  0   |  320 s        |
# |  1   |  1   |  640 s        |
# +------+------+---------------+
WD_SET0=$(( ((5-1)*32)+24 ))
WD_SET1=$(( ((5-1)*32)+23 ))

# Export GPIOs if requested
if [ ! -d "/sys/class/gpio/gpio$WD_SET0" ]; then
    echo $WD_SET0 > "/sys/class/gpio/export" ;
fi
if [ ! -d "/sys/class/gpio/gpio$WD_SET1" ]; then
    echo $WD_SET1 > "/sys/class/gpio/export" ;
fi

# Check if export suceeded, by accessing direction
if [ -f "/sys/class/gpio/gpio$WD_SET0/direction" ] && [ -f "/sys/class/gpio/gpio$WD_SET1/direction" ]; then
    DIR0=$(cat "/sys/class/gpio/gpio$WD_SET0/direction") ;
    DIR1=$(cat "/sys/class/gpio/gpio$WD_SET1/direction") ;
    VALUE0=$(cat "/sys/class/gpio/gpio$WD_SET0/value") ;
    VALUE1=$(cat "/sys/class/gpio/gpio$WD_SET1/value") ;

    # Determine mode
    MODE= ;
    if [ "$DIR0" == "in" ] && [ "$DIR1" == "in" ]; then
        MODE="default" ;
    elif [ "$DIR0" == "in" ] && [ "$DIR1" != "in" ]; then
        MODE="mixed" ;
    elif [ "$DIR0" != "in" ] && [ "$DIR1" == "in" ]; then
        MODE="mixed" ;
    else
        MODE="forced" ;
    fi

    # Determine status
    STATUS= ;
    if [ "$VALUE0" == "1" ] && [ "$VALUE1" == "0" ]; then
        STATUS="disabled" ;
    else
        STATUS="enabled" ;
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




