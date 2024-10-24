SUMMARY = "Aesys base image for production purposes"

inherit core-image

# Normalize image name
IMAGE_NAME = "${IMAGE_LINK_NAME}-image"

# Add squashfs type
IMAGE_FSTYPES += "squashfs"

# Add features
IMAGE_FEATURES += "ssh-server-openssh splash"

# Add packages
IMAGE_INSTALL:append = " aesys-packagegroup-base"

# Create mount dirs
create_mount_dirs() {
    mkdir -p ${IMAGE_ROOTFS}/boot
    mkdir -p ${IMAGE_ROOTFS}/var
    mkdir -p ${IMAGE_ROOTFS}/data
}

IMAGE_PREPROCESS_COMMAND += "create_mount_dirs;"

