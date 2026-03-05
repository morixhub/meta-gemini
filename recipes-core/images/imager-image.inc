# This include file makes any recipe eligible to act as an imager image

# Make rootfs read-only (since it is going to be mounted from NFS RO)
IMAGE_FEATURES:append = " read-only-rootfs "

# Select "tar.zst" format
IMAGE_FSTYPES:append = " tar.zst "

# Install utility packages
IMAGE_INSTALL:append = " nfs-utils-client "

# Add aesys packages
IMAGE_INSTALL:append = " aesys-device-raise-hand "

# Add rootfs customization
ROOTFS_POSTPROCESS_COMMAND += " aesys_imager_image_customize_root; "

aesys_imager_image_customize_root() {

    ########################################################
    # Generate VNC keys

    # Save previous directory
    PREVDIR=`pwd` ;

    # Create directory, if requested
    mkdir -p ${IMAGE_ROOTFS}/etc/vnc/keys ;
    cd ${IMAGE_ROOTFS}/etc/vnc/keys ;

    # Create CA private key...
    openssl genrsa -out cakey.pem 2048 ;

    # ...and CA certificate
    openssl req -new -x509 -nodes -days 14600 -key cakey.pem -subj '/C=IT/ST=Italy/L=Seriate(BG)/CN=aesys.com' -out cacert.pem ;

    # Generate private key for VNC...
    openssl genrsa -out tls.key 2048 ;

    # ...a CSR for that key...
    openssl req -new -key tls.key -out tls.csr -subj '/C=IT/ST=Italy/L=Seriate(BG)/CN=*.aesys.com' ;

    # ...and the correspondent certificate
    openssl x509 -req -days 14600 -in tls.csr -out tls.crt -CA cacert.pem -CAkey cakey.pem ;

    # Restore previous directory
    cd "${PREVDIR}" ;


    ########################################################
    # Add a static IP address on second network adapter (wired1)

    sed -i -e '/iface wired1/d' -e '$ a iface wired1 inet static\n\taddress 192.168.1.1\n\tnetmask 255.255.255.0\n' "${IMAGE_ROOTFS}/etc/network/interfaces" ;


    ########################################################
    # Ensure that Weston has been configured with a kiosk-shell (used for HW testing)

    KIOSK=$(cat "${IMAGE_ROOTFS}/etc/xdg/weston/weston.ini" | grep -v "#" | grep -i "shell=kiosk-shell.so") ;
    if [ -z "$KIOSK" ]; then
        sed -i -e "/^\[core\]/a shell=kiosk-shell.so" "${IMAGE_ROOTFS}/etc/xdg/weston/weston.ini" ;
    fi
}




