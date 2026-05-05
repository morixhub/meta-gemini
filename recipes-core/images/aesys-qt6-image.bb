SUMMARY = "Aesys image for production (Qt6+multimedia)"

# Include basic features from the base image
require aesys-image.bb

# Add Qt 5.x compatibility packages
IMAGE_INSTALL += " \
    qt5compat \
"

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

BASE_IMAGE="recipes-fsl/images/imx-image-multimedia.bb"
BASE_IMAGE:genericx86-64="recipes-graphics/images/core-image-weston.bb"

require ${BASE_IMAGE}

inherit populate_sdk_qt6

CONFLICT_DISTRO_FEATURES = "directfb"

IMAGE_INSTALL += " \
    packagegroup-qt6-imx \
    tzdata \
    ${IMAGE_INSTALL_PKCS11TOOL} \
"

IMAGE_INSTALL:remove:genericx86-64 = "packagegroup-qt6-imx"

IMAGE_INSTALL_PKCS11TOOL = ""
IMAGE_INSTALL_PKCS11TOOL:mx8-nxp-bsp = "opensc pkcs11-provider"
IMAGE_INSTALL_PKCS11TOOL:mx9-nxp-bsp = "opensc pkcs11-provider"

# Remove splash
IMAGE_FEATURES:remove = "splash"

# Avoid installing v2x, docker and g2d_samples
CORE_IMAGE_EXTRA_INSTALL:remove = "packagegroup-imx-v2x"
CORE_IMAGE_EXTRA_INSTALL:remove = "docker"
CORE_IMAGE_EXTRA_INSTALL:remove = "imx-g2d-samples"

