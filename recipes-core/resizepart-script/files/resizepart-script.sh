#!/bin/sh

# Resize partition
logger "Start resizing partition..."
printf 'yes\n100%%' | parted /dev/mmcblk1 resizepart 4 ---pretend-input-tty

# Resize file system
logger "Resizing filesystem..."
/lib/systemd/systemd-growfs /data

# Log
logger "Partition resizing complete"

# Disable systemd service
systemctl disable resizepart-script.service

# Log
logger "resizepart-script service disabled"