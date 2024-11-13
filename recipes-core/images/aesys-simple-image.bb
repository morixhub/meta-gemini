SUMMARY = "Aesys image (simple)"

# Include basic features from the hwtest image
require aesys-image.bb

# Manage root customization
customize_root() {

    # Disable securefs check on simple images
    mkdir -p ${IMAGE_ROOTFS}/var/aesys
    touch ${IMAGE_ROOTFS}/var/aesys/securefs.skip
}

# Add default IP address to simple images
IMAGE_INSTALL += " \
    aesys-default-eth0-ip \
"

IMAGE_PREPROCESS_COMMAND += "customize_root;"