# Core patches
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
# PLL-DIV for 3600MTS have been included in U-Boot mainline, so we can drop the following line
# SRC_URI += " file://0001-Added-PLL-DIV-for-3600MTS.patch"
SRC_URI += " file://0002-Added-Board-Target-Kconfig.patch"
SRC_URI += " file://0003-Added-BroadCom-Phy-Leds-Configuration.patch"
SRC_URI += " file://0004-FIT-Support-For-BootM.patch"
SRC_URI += " file://0005-Fixed-FEC-RMII-Support.patch"
SRC_URI += " file://0006-Dump-CPU-TripPoints.patch"
SRC_URI += " file://0007-Introduced-PXEQuick-Option-And-ARP-Timeout-Configurability.patch"
SRC_URI += " file://0008-PXE-Resolve-EnvVariables-In-Kernel-Config-Name.patch"
SRC_URI += " file://0009-Minimized-UBoot-Warning-Messages.patch"

# Copy additional stuff to working copy after patching
COPYSOURCE := "${THISDIR}/${PN}"
do_after_patch() {

	# COMMON
	cp "${COPYSOURCE}/aesys_bootloader_pubkeys_PKI_TEST.dtsi" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/aesys_bootloader_pubkeys_PKI_AESYS_iMX8_RSA2048.dtsi" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/include/configs/gemini_env.h" "${WORKDIR}/git/include/configs/"
	cp -rf "${COPYSOURCE}/board/aesys" "${WORKDIR}/git/board/"
	
	# Create symlink to freescale common assets
	ln -f -s "${WORKDIR}/git/board/freescale/common" "${WORKDIR}/git/board/aesys/common"

	# AESYS 2319A
	cp "${COPYSOURCE}/aesys_2319a.dts" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/aesys_2319a-u-boot.dtsi" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/configs/aesys_2319a_defconfig" "${WORKDIR}/git/configs/"
	cp "${COPYSOURCE}/include/configs/aesys_2319a.h" "${WORKDIR}/git/include/configs/"

	# AESYS 2409A
	cp "${COPYSOURCE}/aesys_2409a.dts" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/aesys_2409a-u-boot.dtsi" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/configs/aesys_2409a_defconfig" "${WORKDIR}/git/configs/"
	cp "${COPYSOURCE}/include/configs/aesys_2409a.h" "${WORKDIR}/git/include/configs/"

	# AESYS 2414-BASED BOARDS
	cp "${COPYSOURCE}/configs/aesys_2414_defconfig" "${WORKDIR}/git/configs/"
	cp "${COPYSOURCE}/include/configs/aesys_2414.h" "${WORKDIR}/git/include/configs/"
	cp "${COPYSOURCE}/aesys_2414.dtsi" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/aesys_2414-u-boot.dtsi" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/aesys_2414.dts" "${WORKDIR}/git/arch/arm/dts/"

    # AESYS 2414-2G-BASED BOARDS
	cp "${COPYSOURCE}/configs/aesys_2414_2g_defconfig" "${WORKDIR}/git/configs/"
	cp "${COPYSOURCE}/include/configs/aesys_2414_2g.h" "${WORKDIR}/git/include/configs/"
	cp "${COPYSOURCE}/aesys_2414_2g.dtsi" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/aesys_2414_2g-u-boot.dtsi" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/aesys_2414_2g.dts" "${WORKDIR}/git/arch/arm/dts/"

	# AESYS 2602A
	cp "${COPYSOURCE}/aesys_2602a.dts" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/aesys_2602a-u-boot.dtsi" "${WORKDIR}/git/arch/arm/dts/"
	cp "${COPYSOURCE}/configs/aesys_2602a_defconfig" "${WORKDIR}/git/configs/"
	cp "${COPYSOURCE}/include/configs/aesys_2602a.h" "${WORKDIR}/git/include/configs/"
}

addtask after_patch after do_patch before do_configure

