#!/bin/bash

# Get device to be calibrated
DEVICE=$(weston-touch-calibrator 2>/dev/null | grep -e '^device "' | head -n 1 | awk -F \" ' { print $2 } ')

if [ -z $DEVICE ]; then
        echo "Invalid touch device" ;
        exit 1 ;
fi

# Start calibration
weston-touch-calibrator "$DEVICE"
