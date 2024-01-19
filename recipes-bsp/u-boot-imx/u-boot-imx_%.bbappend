FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " file://0001-Added-PLL-DIV-for-3600MTS.patch"

COPYSOURCE := "${THISDIR}/${PN}"

do_after_patch() {
	cp "${COPYSOURCE}/lpddr4_timing.c" "${WORKDIR}/git/board/freescale/imx8mp_evk"
	cp "${COPYSOURCE}/imx8mp-evk.dts" "${WORKDIR}/git/arch/arm/dts"
}

addtask after_patch after do_patch before do_configure

