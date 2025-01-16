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

# 3) CREATE SELF-SIGNED X.509 CERTIFICATE FOR VNC
if [ -d '/etc/vnc/keys' ]; then

    # Log
    do_log "Creating VNC X.509 self-signed certificate..." ;

    # Save previous directory
    PREVDIR=`pwd` ;

    # Change directory
    cd /etc/vnc/keys ;

    # Create CA private key...
    openssl genrsa -out cakey.pem 2048 ;

    # ...and CA certificate
    openssl req -new -x509 -nodes -days 365000 -key cakey.pem -subj '/C=IT/ST=Italy/L=Seriate(BG)/CN=aesys.com' -out cacert.pem ;

    # Generate private key for VNC...
    openssl genrsa -out tls.key 2048 ;

    # ...a CSR for that key...
    openssl req -new -key tls.key -out tls.csr -subj '/C=IT/ST=Italy/L=Seriate(BG)/CN=*.aesys.com' ;

    # ...and the correspondent certificate
    openssl x509 -req -days 365000 -in tls.csr -out tls.crt -CA cacert.pem -CAkey cakey.pem

    # Restore previous directory
    cd "${PREVDIR}" ;
fi

# 4) DISABLE FIRST INITIALIZATION
# Remove trigger file
if [ -e '/var/aesys/firstinit.pending' ]; then

    # Remove file
    rm /var/aesys/firstinit.pending ;
    do_log "First initialization trigger file removed" ;
fi

# 5) SHOW FINAL
do_log "First initialization completed" ;

# 6) COMMAND REBOOT
systemctl reboot
