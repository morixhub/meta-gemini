#!/bin/bash

usage () {
    cat << EOF
Usage: ${0##*/} [-h] <OP>

Enables/disables the HW watchdog, depending on given <OP>.

<OP> can be:
- "disable" for disabling the HW watchdog;
- "enable" for enabling the HW watchdog;
- "default" for setting the HW watchdog enabling at its default state (determine by PUP/PDOWN resistors).

OPTIONS:
-h  Displays this help and exit

RETURN VALUE:
    0: Success (no changes made)
    Other: Error code

EOF
}

# Process options
while getopts h opt; do
    case $opt in
        h)
            usage ;
            exit 0 ;
            ;;
        ?)
            echo >&2 ;
            usage >&2 ;
            exit 1;
            ;;
    esac
done

# Process positional args
OP="${@:$OPTIND:1}"

if [ "$OP" != "enable" ] && [ "$OP" != "disable" ] && [ "$OP" != "default" ]; then
    echo >&2 ;
    usage >&2 ;
    exit 1;
fi

# GPIO5_25 is used for toggling WDOG enabling
WD_GPIO=$(( ((5-1)*32)+25 ))

# Export GPIO if requested
if [ ! -d "/sys/class/gpio/gpio$WD_GPIO" ]; then
    echo $WD_GPIO > "/sys/class/gpio/export" ;
fi

# Check if export suceeded, by accessing direction
if [ -f "/sys/class/gpio/gpio$WD_GPIO/direction" ]; then
    DIR=$(cat "/sys/class/gpio/gpio$WD_GPIO/direction") ;
    if [ "$OP" == "default" ]; then
        # Set direction IN (PUP/PDOWN resistor will rule then)
        if [ "$DIR" != "in" ]; then
            echo "in" > "/sys/class/gpio/gpio$WD_GPIO/direction" ;
        fi
    else
        # Set direction OUT
        if [ "$DIR" != "out" ]; then
            echo "out" > "/sys/class/gpio/gpio$WD_GPIO/direction" ;
        fi

        # Set proper value
        if [ "$OP" == "enable" ]; then
            echo 1 > "/sys/class/gpio/gpio$WD_GPIO/value" ;
        else
            echo 0 > "/sys/class/gpio/gpio$WD_GPIO/value" ;
        fi
    fi
else
    exit 1;
fi




