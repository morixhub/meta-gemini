SUMMARY = "Aesys image for UDisplay"

# Include basic features from the base image
require aesys-qt6-image.bb

# Get rid of unuseful test packages
IMAGE_FEATURES:remove = "tools-testapps"
CORE_IMAGE_EXTRA_INSTALL:remove = "packagegroup-fsl-tools-testapps"
CORE_IMAGE_EXTRA_INSTALL:remove = "packagegroup-fsl-tools-benchmark"

# Add chromium browser to the image
IMAGE_INSTALL += " \
    chromium-ozone-wayland \
"

# Add net-snmp to the image
IMAGE_INSTALL += " \
    net-snmp \
    net-snmp-server-snmpd \
"
