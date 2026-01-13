# Core patches
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " file://Aesys-Kernel-Config-Fragment.cfg"
SRC_URI += " file://0001-Fixed-SpiDev.patch"
SRC_URI += " file://0002-BroadCom-Phy.patch"
SRC_URI += " file://0004-BroadCom-Phy-Avoid-Further-Access-to-DTS.patch"
SRC_URI += " file://0005-Added-Disen-DRM-Panel.patch"
SRC_URI += " file://0006-Fixed-Disen-DRM-Panel.patch"
SRC_URI += " file://0007-Improved-Goodix-GT911-And-Disen-Panel-Drivers.patch"
SRC_URI += " file://0008-Improved-EnableDisable-Disen-Panel.patch"
SRC_URI += " file://0009-Added-SHLR-UPDN-Disen-Panel.patch"
SRC_URI += " file://0010-Fixed-SHLR-UPDN-Disen-Panel.patch"
SRC_URI += " file://0011-Fixed-RPMSG-IMX-driver.patch"
SRC_URI += " file://0012-Reset-And-Power-GPIOs-Now-Optional-For-Disen-Panel.patch"
SRC_URI += " file://0013-Fixed-Optional-UpDn-ShLr-For-Disen-Panel.patch"
SRC_URI += " file://0014-Added-Fixed-Clock-Disable-For-RTC-pcf85063.patch"
SRC_URI += " file://0015-Fixed-RTC-pcf85063-For-SysFS-Entries.patch"
SRC_URI += " file://0017-SGTL5000-Added-MCLK-Generation_For_I2C.patch"
SRC_URI += " file://0018-iMX8-Added-Scaling-Frequencies.patch"

# Include AuFS patches, if requested by distribution
SRC_URI += " ${@bb.utils.contains('DISTRO_FEATURES', 'aufs', 'file://0016-AuFS-Support.patch', '', d)}"

# Remove the commit ID string from kernel version
# ATTENTION: the value of LINUX_VERSION_EXTENSION is not really important here: it is just for
# avoiding that FSL BSP generates something on its own; the correct kernel version is then
# set as part of the kernel configuration fragment
SCMVERSION="n"
LOCAL_VERSION=""
LINUX_VERSION_EXTENSION="+gemini"

# Manage kernel configuration fragments
DELTA_KERNEL_DEFCONFIG:append = "Aesys-Kernel-Config-Fragment.cfg"

# Copy additional stuff to working copy after patching
COPYSOURCE := "${THISDIR}/${PN}"

do_after_patch() {

	# GENERAL
	# Aesys logo
	cp "${COPYSOURCE}/linux_logo.png" "${WORKDIR}/git/drivers/video/logo"
	cp "${COPYSOURCE}/logo_linux_clut224.ppm" "${WORKDIR}/git/drivers/video/logo"

	# AESYS 2319A
	cp "${COPYSOURCE}/aesys_2319a.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"
	cp "${COPYSOURCE}/aesys_2319a_m7.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"

	# AESYS 2409A
	cp "${COPYSOURCE}/aesys_2409a.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"
	cp "${COPYSOURCE}/aesys_2409a_m7.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"

	# AESYS 2414-BASED BOARDS
	cp "${COPYSOURCE}/aesys_2414.dtsi" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"
	cp "${COPYSOURCE}/aesys_2414.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"

    # AESYS 2414-2G-BASED BOARDS
	cp "${COPYSOURCE}/aesys_2414_2g.dtsi" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"
	cp "${COPYSOURCE}/aesys_2414_2g.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"

	# AESYS 2414A
	cp "${COPYSOURCE}/aesys_2414a.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"

    # AESYS 2414B
    cp "${COPYSOURCE}/aesys_2414b.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"

	# AESYS 2415A
	cp "${COPYSOURCE}/aesys_2414a__aesys_2415a.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"
    cp "${COPYSOURCE}/aesys_2414b__aesys_2415a.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"

    # AESYS 2415B
    cp "${COPYSOURCE}/aesys_2414b__aesys_2415b.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"

	# AESYS 2501A
	cp "${COPYSOURCE}/aesys_2414a__aesys_2501a.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"

    # AESYS 2501B
	cp "${COPYSOURCE}/aesys_2414b__aesys_2501b.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"

	# AESYS 2511A
	cp "${COPYSOURCE}/aesys_2414a__aesys_2511a.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"
    cp "${COPYSOURCE}/aesys_2414b__aesys_2511a.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"
}

addtask after_patch after do_patch before do_configure
