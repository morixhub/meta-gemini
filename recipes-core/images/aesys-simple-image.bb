SUMMARY = "Aesys image (simple)"

# Include basic features from the hwtest image
require aesys-image.bb

# Add overlayfs
IMAGE_FEATURES += "read-only-rootfs"
IMAGE_INSTALL += " \
    aesys-overlayfs \
"
