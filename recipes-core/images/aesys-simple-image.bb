SUMMARY = "Aesys image (simple)"

# Include basic features from the hwtest image
require aesys-image.bb

# Add development IP address
IMAGE_FEATURES:append = " aesys-development-ip "

# Simple images, by default, do not enable root overlay
IMAGE_FEATURES:append = " aesys-disable-overlayroot "

# Simple images, by default, do not enable PXE boot
IMAGE_FEATURES:append = " aesys-disable-pxe "