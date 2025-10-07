#!/bin/bash

# GPIO5_22 is used for toggling WDOG status
WD_GPIO=$(( ((5-1)*32)+22 ))

# Export GPIO if requested
if [ ! -d "/sys/class/gpio/gpio$WD_GPIO" ]; then
	echo $WD_GPIO > "/sys/class/gpio/export" ;
fi

if [ -f "/sys/class/gpio/gpio$WD_GPIO/direction" ]; then
	DIR=$(cat "/sys/class/gpio/gpio$WD_GPIO/direction") ;
	if [ "$DIR" != "out" ]; then
		echo out > "/sys/class/gpio/gpio$WD_GPIO/direction" ;
	fi 
else
	exit 1;
fi

if [ ! -f "/sys/class/gpio/gpio$WD_GPIO/value" ]; then
    exit 2;
fi

# Toggle value (the WDOG is sensible on falling edge)
echo 1 > "/sys/class/gpio/gpio$WD_GPIO/value"
sleep 0.25
echo 0 > "/sys/class/gpio/gpio$WD_GPIO/value"
