COPYSOURCE := "${THISDIR}/${PN}"

do_after_patch() {
	cp "${COPYSOURCE}/imx8mp-evk.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"
}

addtask after_patch after do_patch before do_configure