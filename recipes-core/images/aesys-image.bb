SUMMARY = "Aesys base image for production purposes"

inherit core-image

# Add features
IMAGE_FEATURES += "ssh-server-openssh splash"

# Add packages
IMAGE_INSTALL:append = " aesys-packagegroup-base"

# Create mount dirs
create_mount_dirs() {
    mkdir -p ${IMAGE_ROOTFS}/run
    mkdir -p ${IMAGE_ROOTFS}/secure
    mkdir -p ${IMAGE_ROOTFS}/ro
    mkdir -p ${IMAGE_ROOTFS}/boot
    mkdir -p ${IMAGE_ROOTFS}/var
    mkdir -p ${IMAGE_ROOTFS}/data
}

IMAGE_PREPROCESS_COMMAND += "create_mount_dirs;"

