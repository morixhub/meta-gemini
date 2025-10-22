SUMMARY = "Aesys base image for production purposes"

inherit core-image
inherit extrausers
inherit populate_sdk_base

# Extend recognized IMAGE_FEATURES valid items
IMAGE_FEATURES[validitems] += " aesys-development-ip "
IMAGE_FEATURES[validitems] += " aesys-disable-overlayroot "
IMAGE_FEATURES[validitems] += " aesys-disable-pxe "
IMAGE_FEATURES[validitems] += " aesys-disable-static-pxe "
IMAGE_FEATURES[validitems] += " aesys-disable-mixed-pxe "

# Remove nfs-client (because it implies rpcbind, which we want to get rid of, for OS hardening purposes)
IMAGE_FEATURES:remove = "nfs-client"

# Set root's password and related access control
# (encrypted password obtained with command "openssl passwd -1 ae1221")
IMAGE_FEATURES:remove = "debug-tweaks"
IMAGE_FEATURES:append = " allow-root-login "
EXTRA_USERS_PARAMS += "usermod -p '\$1\$FMup4eG7\$5kGXZnwbAA/kNnkqhHLaA1' root;" 

# Static and mixed PXE disabled by default on Aesys base images
IMAGE_FEATURES:append = " aesys-disable-static-pxe "
IMAGE_FEATURES:append = " aesys-disable-mixed-pxe "

# Remove development tools from final image
IMAGE_FEATURES:remove = "tools-sdk"

# Normalize image name
IMAGE_NAME = "${IMAGE_LINK_NAME}-image"

# Set the desired image formats
IMAGE_FSTYPES="wic.bmap wic.zst squashfs"

# Add features
IMAGE_FEATURES:append = " ssh-server-openssh "

# Add psplash (removed now)
#IMAGE_FEATURES:append = " splash "

# Add support for NXP Wi-Fi (IW416)
IMAGE_INSTALL:append:aesys-2414 = " nxp-wlan-sdk moal-auto-startup "
IMAGE_INSTALL:append:aesys-2414-2g = " nxp-wlan-sdk moal-auto-startup "

# Add base packages (some packages cannot be included in aesys-packagegroup-base due to different architecture specialization)
IMAGE_INSTALL:append = " aesys-packagegroup-base "
IMAGE_INSTALL:append = " glibc-utils "

# Add SQLite-related packages
IMAGE_INSTALL:append = " sqlite3 "

# Add Avahi-related packages
IMAGE_INSTALL:append = " avahi-daemon libavahi-core libavahi-common libavahi-client avahi-utils "

# Add PAM and related modules
IMAGE_INSTALL:append = " libpam nss-pam-ldapd pam-radius "

# Add unionfs-fuse packages
IMAGE_INSTALL:append = " unionfs-fuse "

# Add coreutils
IMAGE_INSTALL:append = " coreutils "

# Add pulseaudio
IMAGE_INSTALL:append = " pulseaudio pulseaudio-server pulseaudio-misc pulseaudio-module-dbus-protocol "

# Add AuFS utils, if requested by distribution
IMAGE_INSTALL:append = " ${@bb.utils.contains('DISTRO_FEATURES', 'aufs', ' aufs-utils ', '', d)}"

# Add aesys packages
IMAGE_INSTALL:append = " aesys-so-ver aesys-hw-wdog aesys-automount aesys-persistent-nic-names aesys-firstinit aesys-startup-shutdown "
IMAGE_INSTALL:append:aesys-2414 = " aesys-greenpak-programmer "
IMAGE_INSTALL:append:aesys-2414-2g = " aesys-greenpak-programmer "

# Add rootfs customization
IMAGE_PREPROCESS_COMMAND += " aesys_image_customize_root; "

# If requested, then inject the default IP address intended for development into the image
ROOTFS_POSTPROCESS_COMMAND += '${@bb.utils.contains_any("IMAGE_FEATURES", 'aesys-development-ip', " aesys_development_ip; ", "", d)}'

# If requested, then inject the file for forcing disabled overlay
ROOTFS_POSTPROCESS_COMMAND += '${@bb.utils.contains_any("IMAGE_FEATURES", 'aesys-disable-overlayroot', " aesys_disable_overlayroot; ", "", d)}'

# If requested, then inject the file for forcing disabled PXE
ROOTFS_POSTPROCESS_COMMAND += '${@bb.utils.contains_any("IMAGE_FEATURES", 'aesys-disable-pxe', " aesys_disable_pxe; ", "", d)}'
ROOTFS_POSTPROCESS_COMMAND += '${@bb.utils.contains_any("IMAGE_FEATURES", 'aesys-disable-static-pxe', " aesys_disable_static_pxe; ", "", d)}'
ROOTFS_POSTPROCESS_COMMAND += '${@bb.utils.contains_any("IMAGE_FEATURES", 'aesys-disable-mixed-pxe', " aesys_disable_mixed_pxe; ", "", d)}'

# Root FS customization
aesys_image_customize_root() {

    # Create mount dirs
    mkdir -p ${IMAGE_ROOTFS}/boot ;
    mkdir -p ${IMAGE_ROOTFS}/data ;

    # Create auxiliary dirs
    mkdir -p ${IMAGE_ROOTFS}/data/.sys ;

    # Create writable configuration dir
    mkdir -p ${IMAGE_ROOTFS}/data/etcrw ;

    # Create app dir
    mkdir -p ${IMAGE_ROOTFS}/app ;

    # Disable securefs check by default
    touch ${IMAGE_ROOTFS}/data/.sys/rootfs-securefs.skip ;
    touch ${IMAGE_ROOTFS}/data/.sys/data-securefs.skip ;
    touch ${IMAGE_ROOTFS}/data/.sys/app-securefs.skip ;

    # Set image name
    mkdir -p ${IMAGE_ROOTFS}/etc ;
    echo ${IMAGE_BASENAME} > ${IMAGE_ROOTFS}/etc/image-ver ;
    chmod 0444 ${IMAGE_ROOTFS}/etc/image-ver ;

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

# PXE boot disabling
aesys_disable_pxe () {

    mkdir -p ${IMAGE_ROOTFS}/data/.sys ;
    touch ${IMAGE_ROOTFS}/data/.sys/pxe.disabled ;
}

aesys_disable_static_pxe () {

    mkdir -p ${IMAGE_ROOTFS}/data/.sys ;
    touch ${IMAGE_ROOTFS}/data/.sys/pxe.static.disabled ;
}

aesys_disable_mixed_pxe () {

    mkdir -p ${IMAGE_ROOTFS}/data/.sys ;
    touch ${IMAGE_ROOTFS}/data/.sys/pxe.mixed.disabled ;
}
