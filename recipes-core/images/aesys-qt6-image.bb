SUMMARY = "Aesys image for production (Qt6+multimedia)"

# Include basic features from the base image
require aesys-image.bb

# Add additional Qt packages
IMAGE_INSTALL += " \
    qtmqtt \
    qtmultimedia \
    qtserialport \
    qtserialbus \
    qtwebsockets \
"

# Add QtWebEngine
IMAGE_INSTALL += " \
    qtwebengine \
    qtwebview \
"

# THE REMAINING PART OF THIS RECIPE IS TAKEN DIRECTLY FROM imx-image-full RECIPE FROM NXP
# (sources/meta-imx/meta-imx-sdk/dynamic-layers/qt6-layer/recipes-fsl/images/imx-image-full.bb)

require recipes-fsl/images/imx-image-multimedia.bb

inherit populate_sdk_qt6

CONFLICT_DISTRO_FEATURES = "directfb"

IMAGE_INSTALL += " \
    curl \
    packagegroup-imx-ml \
    packagegroup-qt6-imx \
    tzdata \
    ${IMAGE_INSTALL_PKCS11TOOL} \
"

IMAGE_INSTALL_PKCS11TOOL = ""
IMAGE_INSTALL_PKCS11TOOL:mx8-nxp-bsp = "opensc pkcs11-provider"
IMAGE_INSTALL_PKCS11TOOL:mx9-nxp-bsp = "opensc pkcs11-provider"

