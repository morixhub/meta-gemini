# Core patches
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " file://0001-Fixed-SpiDev.patch"
SRC_URI += " file://0002-BroadCom-Phy.patch"
SRC_URI += " file://0003-BroadCom-Phy-Cleanup.patch"
SRC_URI += " file://0004-BroadCom-Phy-Avoid-Further-Access-to-DTS.patch"
SRC_URI += " file://0005-Added-Disen-DRM-Panel.patch"
SRC_URI += " file://0006-Fixed-Disen-DRM-Panel.patch"
SRC_URI += " file://0007-Improved-Goodix-GT911-And-Disen-Panel-Drivers.patch"
SRC_URI += " file://0008-Improved-EnableDisable-Disen-Panel.patch"
SRC_URI += " file://0009-Added-SHLR-UPDN-Disen-Panel.patch"
SRC_URI += " file://0010-Fixed-SHLR-UPDN-Disen-Panel.patch"
SRC_URI += " file://0011-Fixed-RPMSG-IMX-driver.patch"
SRC_URI += " file://Aesys-Kernel-Config-Fragment.cfg"

# Manage kernel configuration fragments
DELTA_KERNEL_DEFCONFIG:append = "Aesys-Kernel-Config-Fragment.cfg"

# Copy additional stuff to working copy after patching
COPYSOURCE := "${THISDIR}/${PN}"

do_after_patch() {
	cp "${COPYSOURCE}/aesys_2319a.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"
	cp "${COPYSOURCE}/aesys_2319a_m7.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"

	cp "${COPYSOURCE}/aesys_2319a_test.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"
	cp "${COPYSOURCE}/aesys_2319a_test_m7.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"
}

addtask after_patch after do_patch before do_configure