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
    if [ "$OP" == "default" ]; then
        # Set direction IN (PUP/PDOWN resistor will rule then)
        if [ "$DIR0" != "in" ]; then
            echo "in" > "/sys/class/gpio/gpio$WD_SET0/direction" ;
        fi
        if [ "$DIR1" != "in" ]; then
            echo "in" > "/sys/class/gpio/gpio$WD_SET1/direction" ;
        fi
    else
        # Set direction OUT
        if [ "$DIR0" != "out" ]; then
            echo "out" > "/sys/class/gpio/gpio$WD_SET0/direction" ;
        fi
        if [ "$DIR1" != "out" ]; then
            echo "out" > "/sys/class/gpio/gpio$WD_SET1/direction" ;
        fi

        # Set proper value
        if [ "$OP" == "enable" ]; then
            echo 1 > "/sys/class/gpio/gpio$WD_SET0/value" ;
            echo 1 > "/sys/class/gpio/gpio$WD_SET1/value" ;
        else
            echo 1 > "/sys/class/gpio/gpio$WD_SET0/value" ;
            echo 0 > "/sys/class/gpio/gpio$WD_SET1/value" ;
        fi
    fi
else
    exit 1;
fi




