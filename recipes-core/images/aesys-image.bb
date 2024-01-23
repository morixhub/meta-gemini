SUMMARY = "Aesys production image"

inherit core-image

IMAGE_FEATURES += "ssh-server-openssh splash"

IMAGE_INSTALL:append = " wireless-regdb-static aesys-packagegroup-base"