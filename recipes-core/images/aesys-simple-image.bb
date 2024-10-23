SUMMARY = "Aesys image (simple)"

# Include basic features from the hwtest image
require aesys-image.bb

# Make system system root read-only
IMAGE_FEATURES += "read-only-rootfs"
