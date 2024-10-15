FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Remove patch from meta-imx dynamic layers...
SRC_URI:remove:imx-nxp-bsp = " \
    file://0003-Disable-dri-for-imx-gpu.patch \
"

# ...since they've been incorporated here:
SRC_URI:append:imx-nxp-bsp = " \
    file://0001-Disable-dri-for-imx-gpu.patch \
"