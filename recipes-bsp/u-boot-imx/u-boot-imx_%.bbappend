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
	cp "${COPYSOURCE}/aesys_bootloader_pubkeys_PKI_TEST.dtsi" "${S}/dts/upstream/src/arm64/freescale/"
	cp "${COPYSOURCE}/aesys_bootloader_pubkeys_PKI_AESYS_iMX8_RSA2048.dtsi" "${S}/dts/upstream/src/arm64/freescale/"
	cp "${COPYSOURCE}/include/configs/gemini_env.h" "${S}/include/configs/"
	cp -rf "${COPYSOURCE}/board/aesys" "${S}/board/"
	
	# Create symlink to freescale common assets
	ln -f -s "${S}/board/freescale/common" "${S}/board/aesys/common"

	# AESYS 2319A
	cp "${COPYSOURCE}/aesys_2319a.dts" "${S}/dts/upstream/src/arm64/freescale/"
	cp "${COPYSOURCE}/aesys_2319a-u-boot.dtsi" "${S}/dts/upstream/src/arm64/freescale/"
	cp "${COPYSOURCE}/configs/aesys_2319a_defconfig" "${S}/configs/"
	cp "${COPYSOURCE}/include/configs/aesys_2319a.h" "${S}/include/configs/"

	# AESYS 2409A
	cp "${COPYSOURCE}/aesys_2409a.dts" "${S}/dts/upstream/src/arm64/freescale/"
	cp "${COPYSOURCE}/aesys_2409a-u-boot.dtsi" "${S}/dts/upstream/src/arm64/freescale/"
	cp "${COPYSOURCE}/configs/aesys_2409a_defconfig" "${S}/configs/"
	cp "${COPYSOURCE}/include/configs/aesys_2409a.h" "${S}/include/configs/"

	# AESYS 2414-BASED BOARDS
	cp "${COPYSOURCE}/configs/aesys_2414_defconfig" "${S}/configs/"
	cp "${COPYSOURCE}/include/configs/aesys_2414.h" "${S}/include/configs/"
	cp "${COPYSOURCE}/aesys_2414.dtsi" "${S}/dts/upstream/src/arm64/freescale/"
	cp "${COPYSOURCE}/aesys_2414-u-boot.dtsi" "${S}/dts/upstream/src/arm64/freescale/"
	cp "${COPYSOURCE}/aesys_2414.dts" "${S}/dts/upstream/src/arm64/freescale/"

    # AESYS 2414-2G-BASED BOARDS
	cp "${COPYSOURCE}/configs/aesys_2414_2g_defconfig" "${S}/configs/"
	cp "${COPYSOURCE}/include/configs/aesys_2414_2g.h" "${S}/include/configs/"
	cp "${COPYSOURCE}/aesys_2414_2g.dtsi" "${S}/dts/upstream/src/arm64/freescale/"
	cp "${COPYSOURCE}/aesys_2414_2g-u-boot.dtsi" "${S}/dts/upstream/src/arm64/freescale/"
	cp "${COPYSOURCE}/aesys_2414_2g.dts" "${S}/dts/upstream/src/arm64/freescale/"

	# AESYS 2602A
	cp "${COPYSOURCE}/aesys_2602a.dts" "${S}/dts/upstream/src/arm64/freescale/"
	cp "${COPYSOURCE}/aesys_2602a-u-boot.dtsi" "${S}/dts/upstream/src/arm64/freescale/"
	cp "${COPYSOURCE}/configs/aesys_2602a_defconfig" "${S}/configs/"
	cp "${COPYSOURCE}/include/configs/aesys_2602a.h" "${S}/include/configs/"
}

addtask after_patch after do_patch before do_configure

