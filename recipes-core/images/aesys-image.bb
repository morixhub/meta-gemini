SUMMARY = "Aesys base image for production purposes"

inherit core-image
inherit extrausers
inherit populate_sdk_base

# Extend recognized IMAGE_FEATURES valid items
IMAGE_FEATURES[validitems] += " aesys-development-ip "
IMAGE_FEATURES[validitems] += " aesys-disable-overlayroot "

# Remove nfs-client (because it implies rpcbind, which we want to get rid of, for OS hardening purposes)
IMAGE_FEATURES:remove = "nfs-client"

# Set root's password and related access control
# (encrypted password obtained with command "openssl passwd -1 ae1221")
IMAGE_FEATURES:remove = "debug-tweaks"
IMAGE_FEATURES:append = " allow-root-login "
EXTRA_USERS_PARAMS += "usermod -p '\$1\$FMup4eG7\$5kGXZnwbAA/kNnkqhHLaA1' root;" 

# Remove development tools from final image
IMAGE_FEATURES:remove = "tools-sdk"

# Normalize image name
IMAGE_NAME = "${IMAGE_LINK_NAME}-image"

# Remove unused "tar.zst" format
IMAGE_FSTYPES:remove = "tar.zst"

# Add squashfs type
IMAGE_FSTYPES:append = " squashfs "

# Add features
IMAGE_FEATURES:append = " ssh-server-openssh splash "

# Add base packages (some packages cannot be included in aesys-packagegroup-base due to different architecture specialization)
IMAGE_INSTALL:append = " aesys-packagegroup-base "
IMAGE_INSTALL:append = " glibc-utils "

# Add SQLite-related packages
IMAGE_INSTALL:append = " sqlite3 "

# Add Avahi-related packages
IMAGE_INSTALL:append = " avahi-daemon libavahi-core libavahi-common libavahi-client avahi-utils "

# Add unionfs-fuse packages
IMAGE_INSTALL:append = " unionfs-fuse "

# Add coreutils
IMAGE_INSTALL:append = " coreutils "

# Add AuFS utils, if requested by distribution
IMAGE_INSTALL:append = " ${@bb.utils.contains('DISTRO_FEATURES', 'aufs', ' aufs-utils ', '', d)}"

# Add aesys packages
IMAGE_INSTALL:append = " aesys-automount aesys-persistent-nic-names aesys-firstinit aesys-startup-shutdown "
IMAGE_INSTALL:append:aesys-2414 = " aesys-greenpak-programmer "

# Add rootfs customization
IMAGE_PREPROCESS_COMMAND += " aesys_image_customize_root; "

# If requested, then inject the default IP address intended for development into the image
ROOTFS_POSTPROCESS_COMMAND += '${@bb.utils.contains_any("IMAGE_FEATURES", 'aesys-development-ip', " aesys_development_ip; ", "", d)}'

# If requested, then inject the file for forcing disabled overlay
ROOTFS_POSTPROCESS_COMMAND += '${@bb.utils.contains_any("IMAGE_FEATURES", 'aesys-disable-overlayroot', " aesys_disable_overlayroot; ", "", d)}'

# Root FS customization
aesys_image_customize_root() {

    # Create mount dirs
    mkdir -p ${IMAGE_ROOTFS}/boot ;
    mkdir -p ${IMAGE_ROOTFS}/data ;

    # Create auxiliary dirs
    mkdir -p ${IMAGE_ROOTFS}/data/.sys ;

    # Create writable configuration dir
    mkdir -p ${IMAGE_ROOTFS}/data/etcrw

    # Disable securefs check by default
    touch ${IMAGE_ROOTFS}/data/.sys/securefs.skip ;

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
    
    sed -i 's|^iface wired0 inet dhcp.*|iface wired0 inet static\n\taddress 192.168.79.18\n\tnetmask 255.255.255.0\n|' ${IMAGE_ROOTFS}${sysconfdir}/network/interfaces
}

# Root overlay disabling
aesys_disable_overlayroot () {

    mkdir -p ${IMAGE_ROOTFS}/data/.sys ;
    touch ${IMAGE_ROOTFS}/data/.sys/overlayroot.disabled ;
}


