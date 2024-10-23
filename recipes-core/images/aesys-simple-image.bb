SUMMARY = "Aesys image (simple)"

# Include basic features from the hwtest image
require aesys-image.bb

# Manage root customization
customize_root() {

    # Disable securefs check on simple images
    mkdir -p ${IMAGE_ROOTFS}/var/aesys
    touch ${IMAGE_ROOTFS}/var/aesys/securefs.skip
}

IMAGE_PREPROCESS_COMMAND += "customize_root;"