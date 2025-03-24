#!/bin/bash

# Locate boot device
# (it is necessary because the boot device changes booting from uSD or eMMC)
BOOT_DEVICE=`cat /proc/cmdline | sed -e 's/^.*root=//' -e 's/ .*$//' | sed 's/..$//'`

# Expose boot device as USB mass storage gadget
modprobe g_mass_storage file=${BOOT_DEVICE} stall=0 removable=1 ro=1 iManufacturer="Aesys" iProduct="Aesys Mass Storage Gadget"

# Launch /app/start.sh, if any
if [ -x /app/start.sh ]; then
    /app/start.sh &
fi
