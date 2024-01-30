SUMMARY = "Aesys image for HW testing (with multimedia)"

# Include basic features from the hwtest image
require aesys-hwtest-image.bb

# Include features from the IMX multimedia image
require recipes-fsl/images/imx-image-multimedia.bb
