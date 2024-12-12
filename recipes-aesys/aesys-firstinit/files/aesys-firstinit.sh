#!/bin/sh

# FUNCTIONS DECLARATIONS
do_log() {
	logger "FIRSTINIT: $1"
}

# PERFORM FIRST INITILIZATION
# 0) Locate boot device
# (it is necessary because the boot device changes booting from uSD or eMMC)
BOOT_DEVICE=`cat /proc/cmdline | sed -e 's/^.*root=//' -e 's/ .*$//' | sed 's/..$//'`

# 1) SHOW SPLASH
do_log "Performing first system initialization..."

# 2) RESIZE DATA PARTITION
# Determine the partition number to be resized
PARTNUMBER=`mount | grep /data | awk '{ print $1 }' | awk '{ print substr($0,length($0),1) }'`

if [ -z $PARTNUMBER ]; then

    # Log
    do_log "Cannot determine the partition number to be resized: giving up..." ;

else
    # Resize partition
    do_log "Resizing partition #$PARTNUMBER..." ;
    printf 'yes\n100%%' | parted ${BOOT_DEVICE} resizepart $PARTNUMBER ---pretend-input-tty ;

    
    # Resize file system
    do_log "Resizing filesystem..." ;
    /lib/systemd/systemd-growfs /data ;

    # Log
    do_log "Partition #$PARTNUMER resizing complete" ;

fi

# 3) DISABLE FIRST INITIALIZATION
# Remove trigger file
if [ -e '/var/aesys/firstinit.pending' ]; then

    # Remove file
    rm /var/aesys/firstinit.pending ;
    do_log "First initialization trigger file removed" ;
fi

# 4) SHOW FINAL
do_log "First initialization completed" ;

# 5) COMMAND REBOOT
systemctl reboot
