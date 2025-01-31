SUMMARY = "Aesys base image for production purposes"

inherit core-image
inherit extrausers

# Extend recognized IMAGE_FEATURES valid items
IMAGE_FEATURES[validitems] += " aesys-development-ip "

# Remove nfs-client (because it implies rpcbind, which we want to get rid of, for OS hardening purposes)
IMAGE_FEATURES:remove = "nfs-client"

# Set root's password and related access control
# (encrypted password obtained with command "openssl passwd -1 ae1221")
IMAGE_FEATURES:remove = "debug-tweaks"
IMAGE_FEATURES:append = " allow-root-login "
EXTRA_USERS_PARAMS += "usermod -p '\$1\$FMup4eG7\$5kGXZnwbAA/kNnkqhHLaA1' root;" 

# Normalize image name
IMAGE_NAME = "${IMAGE_LINK_NAME}-image"

# Add squashfs type
IMAGE_FSTYPES:append = " squashfs "

# Add features
IMAGE_FEATURES:append = " ssh-server-openssh splash "

# Add packages
IMAGE_INSTALL:append = " aesys-packagegroup-base "

# Add aesys packages
IMAGE_INSTALL:append = " aesys-firstinit aesys-startup-shutdown "

# Add rootfs customization
IMAGE_PREPROCESS_COMMAND += " aesys_image_customize_root; "

# If requested, then inject the default IP address intended for development into the image
ROOTFS_POSTPROCESS_COMMAND += '${@bb.utils.contains_any("IMAGE_FEATURES", 'aesys-development-ip', " aesys_development_ip; ", "", d)}'

# Root FS customization
aesys_image_customize_root() {

    # Create mount dirs
    mkdir -p ${IMAGE_ROOTFS}/boot
    mkdir -p ${IMAGE_ROOTFS}/var
    mkdir -p ${IMAGE_ROOTFS}/data

    # Mark the system for requiring first initialization
    mkdir -p ${IMAGE_ROOTFS}/var/aesys
    touch ${IMAGE_ROOTFS}/var/aesys/firstinit.pending

    # Disable securefs check by default
    mkdir -p ${IMAGE_ROOTFS}/var/aesys
    touch ${IMAGE_ROOTFS}/var/aesys/securefs.skip

    #######################################################
    # OS HARDENING BEGIN
    #######################################################
    if [ -f ${IMAGE_ROOTFS}/etc/shadow ]; then
        chown root:root ${IMAGE_ROOTFS}/etc/shadow ;
        chmod 640 ${IMAGE_ROOTFS}/etc/shadow ;
    fi

    if [ -f ${IMAGE_ROOTFS}/etc/gshadow ]; then
        chown root:root ${IMAGE_ROOTFS}/etc/gshadow ;
        chmod 640 ${IMAGE_ROOTFS}/etc/gshadow ;
    fi

    if [ -f ${IMAGE_ROOTFS}/etc/passwd- ]; then
        chown root:root ${IMAGE_ROOTFS}/etc/passwd- ;
        chmod 600 ${IMAGE_ROOTFS}/etc/passwd- ;
    fi

    if [ -f ${IMAGE_ROOTFS}/etc/shadow- ]; then
        chown root:root ${IMAGE_ROOTFS}/etc/shadow- ;
        chmod 640 ${IMAGE_ROOTFS}/etc/shadow- ;
    fi

    if [ -d ${IMAGE_ROOTFS}/home/weston ]; then
        chmod 750 ${IMAGE_ROOTFS}/home/weston ;
    fi

    if [ -d ${IMAGE_ROOTFS}/etc/cron.hourly ]; then
        chown root:root ${IMAGE_ROOTFS}/etc/cron.hourly ;
        chmod 700 ${IMAGE_ROOTFS}/etc/cron.hourly ;
    fi

    if [ -d ${IMAGE_ROOTFS}/etc/cron.daily ]; then
        chown root:root ${IMAGE_ROOTFS}/etc/cron.daily ;
        chmod 700 ${IMAGE_ROOTFS}/etc/cron.daily ;
    fi

    if [ -d ${IMAGE_ROOTFS}/etc/cron.weekly ]; then
        chown root:root ${IMAGE_ROOTFS}/etc/cron.weekly ;
        chmod 700 ${IMAGE_ROOTFS}/etc/cron.weekly ;
    fi

    if [ -d ${IMAGE_ROOTFS}/etc/cron.monthly ]; then
        chown root:root ${IMAGE_ROOTFS}/etc/cron.monthly ;
        chmod 700 ${IMAGE_ROOTFS}/etc/cron.monthly ;
    fi

    if [ -d ${IMAGE_ROOTFS}/etc/cron.d ]; then
        chown root:root ${IMAGE_ROOTFS}/etc/cron.d ;
        chmod 700 ${IMAGE_ROOTFS}/etc/cron.d ;
    fi

    if [ -f ${IMAGE_ROOTFS}/etc/cron.deny ]; then
        rm ${IMAGE_ROOTFS}/etc/cron.deny ;
    fi

    if [ -f ${IMAGE_ROOTFS}/etc/at.deny ]; then
        rm ${IMAGE_ROOTFS}/etc/at.deny ;
    fi
    #######################################################
    # OS HARDENING END
    #######################################################
}

# Managing of development IP address
aesys_development_ip () {
    
    sed -i 's|^iface eth0 inet dhcp.*|iface eth0 inet static\n\taddress 192.168.79.18\n\tnetmask 255.255.255.0\n|' ${IMAGE_ROOTFS}${sysconfdir}/network/interfaces
}




