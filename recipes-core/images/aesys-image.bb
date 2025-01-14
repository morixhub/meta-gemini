SUMMARY = "Aesys base image for production purposes"

inherit core-image
inherit extrausers

# Set root's password and related access control
# (encrypted password obtained with command "openssl passwd -1 ae1221")
IMAGE_FEATURES:remove = "debug-tweaks"
IAMGE_FEATUREs:append = "allow-root-login"
EXTRA_USERS_PARAMS += "usermod -p '\$1\$FMup4eG7\$5kGXZnwbAA/kNnkqhHLaA1' root;" 

# Normalize image name
IMAGE_NAME = "${IMAGE_LINK_NAME}-image"

# Add squashfs type
IMAGE_FSTYPES += "squashfs"

# Add features
IMAGE_FEATURES += "ssh-server-openssh splash"

# Add packages
IMAGE_INSTALL:append = " aesys-packagegroup-base"

# Add aesys packages
IMAGE_INSTALL:append = " aesys-firstinit aesys-startup-shutdown "

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
}

IMAGE_PREPROCESS_COMMAND += " aesys_image_customize_root; "



