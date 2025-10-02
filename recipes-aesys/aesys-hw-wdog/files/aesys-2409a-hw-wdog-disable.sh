#!/bin/bash

# GPIO1_01 is used for toggling WDOG enabling
WD_GPIO=$(( ((1-1)*32)+1 ))

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

echo 0 > "/sys/class/gpio/gpio$WD_GPIO/value"


