#!/bin/sh

# FUNCTIONS DECLARATIONS
do_log() {
	logger "FIRSTINIT: $1"
}

disable_wdog() {
    if [ -x "/usr/bin/hw-wdog-toggle.sh" ]; then
        do_log "Disabling watchdog..." ;
        /usr/bin/hw-wdog-toggle.sh disable ;
    fi
}

restore_wdog() {
    if [ -x "/usr/bin/hw-wdog-toggle.sh" ]; then
        do_log "Restoring watchdog..." ;
        /usr/bin/hw-wdog-toggle.sh default ;
    fi
}

# PERFORM FIRST INITILIZATION
# 1) SHOW SPLASH
do_log "Performing first system initialization..."

# 2) DISABLE WDOG
disable_wdog

# 3) SAMPLE ACTIVE HALF
KERNEL_CMDLINE=`cat /proc/cmdline`
DB_CMDLINE=`echo ${KERNEL_CMDLINE} | grep "db_active_half="`

# 4) CREATE SELF-SIGNED X.509 CERTIFICATE FOR VNC
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
    openssl req -new -x509 -nodes -days 14600 -key cakey.pem -subj '/C=IT/ST=Italy/L=Seriate(BG)/CN=aesys.com' -out cacert.pem ;

    # Generate private key for VNC...
    openssl genrsa -out tls.key 2048 ;

    # ...a CSR for that key...
    openssl req -new -key tls.key -out tls.csr -subj '/C=IT/ST=Italy/L=Seriate(BG)/CN=*.aesys.com' ;

    # ...and the correspondent certificate
    openssl x509 -req -days 14600 -in tls.csr -out tls.crt -CA cacert.pem -CAkey cakey.pem

    # Restore previous directory
    cd "${PREVDIR}" ;
fi

# 5) INITIALIZE HALVES ID FILES
if [ ! -z "${DB_CMDLINE}" ]; then
    if [ -x /initram/dual-tool-id.sh ]; then
        do_log "Synchronizing half "A" ID file..." ;
        /initram/dual-tool-id.sh -b -t a -s ;

        do_log "Synchronizing half "B" ID file..." ;
        /initram/dual-tool-id.sh -b -t b -s ;
    fi
fi

# 6) DISABLE FIRST INITIALIZATION
# Remove trigger file
if [ -e '/data/.sys/firstinit.pending' ]; then

    # Remove file
    rm /data/.sys/firstinit.pending ;
    do_log "First initialization trigger file removed" ;
fi

# 7) FLAG THE BOOT AS SUCCESFULL, IN CASE OF DUAL-BOOT AWARE SYSTEMS
if [ ! -z "${DB_CMDLINE}" ]; then
    fw_setenv db_last_half
fi

# 8) SHOW FINAL
do_log "First initialization completed" ;

# 9) RESTORE WDOG
restore_wdog

# 10) TRIGGER REBOOT
reboot
