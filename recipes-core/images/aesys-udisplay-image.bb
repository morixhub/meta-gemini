SUMMARY = "Aesys image for UDisplay"

# Include basic features from the base image
require aesys-qt6-image.bb

# Add chromium browser to the image
IMAGE_INSTALL += " \
    chromium-ozone-wayland \
"

# Add net-snmp to the image
IMAGE_INSTALL += " \
    net-snmp \
    net-snmp-server-snmpd \
"
