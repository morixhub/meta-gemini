SUMMARY = "Aesys image (simple)"

# Include basic features from the hwtest image
require aesys-image.bb

# Add default IP address to simple images
IMAGE_INSTALL += " \
    aesys-default-eth0-ip \
"
