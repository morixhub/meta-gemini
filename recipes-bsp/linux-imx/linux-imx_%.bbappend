# Core patches
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " file://Aesys-Kernel-Config-Fragment.cfg"
SRC_URI += " file://0001-Fixed-SpiDev.patch"
SRC_URI += " file://0002-BroadCom-Phy.patch"
SRC_URI += " file://0005-Added-Disen-DRM-Panel.patch"
SRC_URI += " file://0007-Improved-Goodix-GT911-Driver.patch"
SRC_URI += " file://0011-Fixed-RPMSG-IMX-driver.patch"
SRC_URI += " file://0015-Restored-Driver-pcf85063-v1.0-With-SysFS-Entries.patch"
SRC_URI += " file://0017-SGTL5000-Added-MCLK-Generation_For_I2C.patch"
SRC_URI += " file://0018-iMX8-Added-Scaling-Frequencies.patch"

# Include AuFS patches, if requested by distribution
SRC_URI += " ${@bb.utils.contains('DISTRO_FEATURES', 'aufs', 'file://0016-AuFS-Support.patch', '', d)}"

# Remove the commit ID string from kernel version
# ATTENTION: the value of LINUX_VERSION_EXTENSION is not really important here: it is just for
# avoiding that FSL BSP generates something on its own; the correct kernel version is then
# set as part of the kernel configuration fragment
SCMVERSION = "n"
LOCAL_VERSION = ""
LINUX_VERSION_EXTENSION = "+gemini"

# Copy additional stuff to working copy after patching
COPYSOURCE := "${THISDIR}/${PN}"
do_after_patch() {

	# GENERAL
	# Aesys logo
	cp "${COPYSOURCE}/linux_logo.png" "${S}/drivers/video/logo"
	cp "${COPYSOURCE}/logo_linux_clut224.ppm" "${S}/drivers/video/logo"

	# AESYS 2319A
	cp "${COPYSOURCE}/aesys_2319a.dts" "${S}/arch/arm64/boot/dts/freescale"
	cp "${COPYSOURCE}/aesys_2319a_m7.dts" "${S}/arch/arm64/boot/dts/freescale"

	# AESYS 2409A
	cp "${COPYSOURCE}/aesys_2409a.dts" "${S}/arch/arm64/boot/dts/freescale"
	cp "${COPYSOURCE}/aesys_2409a_m7.dts" "${S}/arch/arm64/boot/dts/freescale"

	# AESYS 2409C
	cp "${COPYSOURCE}/aesys_2409c.dts" "${S}/arch/arm64/boot/dts/freescale"

	# AESYS 2414-BASED BOARDS
	cp "${COPYSOURCE}/aesys_2414.dtsi" "${S}/arch/arm64/boot/dts/freescale"
	cp "${COPYSOURCE}/aesys_2414.dts" "${S}/arch/arm64/boot/dts/freescale"

    # AESYS 2414-2G-BASED BOARDS
	cp "${COPYSOURCE}/aesys_2414_2g.dtsi" "${S}/arch/arm64/boot/dts/freescale"
	cp "${COPYSOURCE}/aesys_2414_2g.dts" "${S}/arch/arm64/boot/dts/freescale"

	# AESYS 2414A
	cp "${COPYSOURCE}/aesys_2414a.dts" "${S}/arch/arm64/boot/dts/freescale"

    # AESYS 2414B
    cp "${COPYSOURCE}/aesys_2414b.dts" "${S}/arch/arm64/boot/dts/freescale"

	# AESYS 2415A
	cp "${COPYSOURCE}/aesys_2414a__aesys_2415a.dts" "${S}/arch/arm64/boot/dts/freescale"
    cp "${COPYSOURCE}/aesys_2414b__aesys_2415a.dts" "${S}/arch/arm64/boot/dts/freescale"

    # AESYS 2415B
    cp "${COPYSOURCE}/aesys_2414b__aesys_2415b.dts" "${S}/arch/arm64/boot/dts/freescale"

	# AESYS 2501A
	cp "${COPYSOURCE}/aesys_2414a__aesys_2501a.dts" "${S}/arch/arm64/boot/dts/freescale"

    # AESYS 2501B
	cp "${COPYSOURCE}/aesys_2414b__aesys_2501b.dts" "${S}/arch/arm64/boot/dts/freescale"

	# AESYS 2511A
	cp "${COPYSOURCE}/aesys_2414a__aesys_2511a.dts" "${S}/arch/arm64/boot/dts/freescale"
    cp "${COPYSOURCE}/aesys_2414b__aesys_2511a.dts" "${S}/arch/arm64/boot/dts/freescale"

	# AESYS 2602A
	cp "${COPYSOURCE}/aesys_2602a.dts" "${S}/arch/arm64/boot/dts/freescale"
}

addtask after_patch after do_patch before do_configure
