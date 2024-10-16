# Core patches
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
# PLL-DIV for 3600MTS have been included in U-Boot mainline, so we can drop the following line
# SRC_URI += " file://0001-Added-PLL-DIV-for-3600MTS.patch"
SRC_URI += " file://0002-Added-Board-Target-Kconfig.patch"
SRC_URI += " file://0003-Added-BroadCom-Phy-Leds-Configuration.patch"
SRC_URI += " file://0004-FIT-Support-For-BootM.patch"

# Copy additional stuff to working copy after patching
COPYSOURCE := "${THISDIR}/${PN}"
do_after_patch() {
	cp "${COPYSOURCE}/aesys_2319a.dts" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/aesys_2319a-u-boot.dtsi" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/configs/aesys_2319a_defconfig" "${WORKDIR}/git/configs/"
	cp "${COPYSOURCE}/include/configs/aesys_2319a.h" "${WORKDIR}/git/include/configs/"

	cp "${COPYSOURCE}/aesys_2319a_test.dts" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/aesys_2319a_test-u-boot.dtsi" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/configs/aesys_2319a_test_defconfig" "${WORKDIR}/git/configs/"
	cp "${COPYSOURCE}/include/configs/aesys_2319a_test.h" "${WORKDIR}/git/include/configs/"

	cp "${COPYSOURCE}/aesys_bootloader_pubkeys.dtsi" "${WORKDIR}/git/arch/arm/dts/"
	cp -rf "${COPYSOURCE}/board/aesys" "${WORKDIR}/git/board/"

	# Create symlink to freescale common assets
	ln -f -s "${WORKDIR}/git/board/freescale/common" "${WORKDIR}/git/board/aesys/common"
}

addtask after_patch after do_patch before do_configure

