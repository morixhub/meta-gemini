#!/bin/bash

# Launch /app/stop.sh, if any
if [ -x /app/stop.sh ]; then
    /app/stop.sh &
fi

# Lazy-umount boot, var and data (for avoiding troubles with system shutdown)
sync
umount -l /boot
umount -l /data
umount -l /var
