SUMMARY = "Aesys image (simple)"

# Include basic features from the hwtest image
require aesys-image.bb

# Add development IP address
IMAGE_FEATURES:append = " aesys-development-ip "