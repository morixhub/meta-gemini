SUMMARY = "Aesys image for HW testing (with multimedia)"

# Include basic features from the hwtest image
require aesys-image.bb

# Add chromium browser to the image
IMAGE_INSTALL += " \
    chromium-ozone-wayland"

# Add additional Qt packages
IMAGE_INSTALL += " \
    qtmqtt \
    qtmultimedia \
    qtserialport \
    qtserialbus \
    qtwebengine \
    qtwebsockets \
    qtwebview"

# THE REMAINING PART OF THIS RECIPE IS TAKEN DIRECTLY FROM imx-image-full RECIPE FROM NXP
# Include features from the IMX multimedia image
require recipes-fsl/images/imx-image-multimedia.bb

# Add support to Qt6
inherit populate_sdk_qt6

CONFLICT_DISTRO_FEATURES = "directfb"

IMAGE_INSTALL += " \
    curl \
    packagegroup-imx-ml \
    packagegroup-qt6-imx \
    tzdata \
    ${IMAGE_INSTALL_OPENCV} \
    ${IMAGE_INSTALL_PARSEC}"

IMAGE_INSTALL_OPENCV              = ""
IMAGE_INSTALL_OPENCV:imxgpu       = "${IMAGE_INSTALL_OPENCV_PKGS}"
IMAGE_INSTALL_OPENCV:mx93-nxp-bsp = "${IMAGE_INSTALL_OPENCV_PKGS}"
IMAGE_INSTALL_OPENCV_PKGS = " \
    opencv-apps \
    opencv-samples \
    python3-opencv"

IMAGE_INSTALL_PARSEC = " \
    packagegroup-security-tpm2 \
    packagegroup-security-parsec \
    swtpm \
    softhsm \
    os-release \
    ${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'optee-client optee-os', '', d)}"
