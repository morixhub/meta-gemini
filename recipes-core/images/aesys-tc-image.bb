SUMMARY = "Aesys image for TC"

# Include basic features from the base image
require aesys-qt6-image.bb

# Get rid of unuseful test packages
IMAGE_FEATURES:remove = "tools-testapps"
CORE_IMAGE_EXTRA_INSTALL:remove = "packagegroup-fsl-tools-testapps"
CORE_IMAGE_EXTRA_INSTALL:remove = "packagegroup-fsl-tools-benchmark"

# Aesys TC images, by default, do not enable PXE boot
IMAGE_FEATURES:append = " aesys-disable-pxe "

