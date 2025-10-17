# This include file makes any recipe eligible to act as an imager image

# Make rootfs read-only (since it is going to be mounted from NFS RO)
IMAGE_FEATURES:append = " read-only-rootfs "

# Select "tar.zst" format
IMAGE_FSTYPES="tar.zst"

# Install utility packages
IMAGE_INSTALL:append = " nfs-utils-client "

# Add aesys packages
IMAGE_INSTALL:append = " aesys-device-raise-hand "

# Add rootfs customization
ROOTFS_POSTPROCESS_COMMAND += " aesys_imager_image_customize_root; "

aesys_imager_image_customize_root() {

    # Generate VNC keys
    # Save previous directory
    PREVDIR=`pwd` ;

    # Create directory, if requested
    mkdir -p ${IMAGE_ROOTFS}/etc/vnc/keys
    cd ${IMAGE_ROOTFS}/etc/vnc/keys

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
}




