SUMMARY = "Aesys image for HW testing"

inherit core-image

require aesys-image.bb

IMAGE_FEATURES += "tools-debug debug-tweaks"

IMAGE_INSTALL:append = " aesys-packagegroup-hwtest"