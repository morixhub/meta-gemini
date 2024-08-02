SUMMARY = "Aesys production image"

inherit core-image

# Add features
IMAGE_FEATURES += "ssh-server-openssh splash"

# Add packages
IMAGE_INSTALL:append = " aesys-packagegroup-base"

