# Core patches
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " file://0001-Added-PLL-DIV-for-3600MTS.patch"
SRC_URI += " file://0002-Added-Board-Target-Kconfig.patch"

# Copy additional stuff to working copy after patching
COPYSOURCE := "${THISDIR}/${PN}"
do_after_patch() {
	cp "${COPYSOURCE}/aesys_2319a.dts" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/aesys_2319a-u-boot.dtsi" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/configs/aesys_2319a_defconfig" "${WORKDIR}/git/configs/"
	cp "${COPYSOURCE}/include/configs/aesys_2319a.h" "${WORKDIR}/git/include/configs/"
	cp -rf "${COPYSOURCE}/board/aesys" "${WORKDIR}/git/board/"

	# Create symlink to freescale common assets
	ln -s "${WORKDIR}/git/board/freescale/common" "${WORKDIR}/git/board/aesys/common"
}

addtask after_patch after do_patch before do_configure

