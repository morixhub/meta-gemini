COPYSOURCE := "${THISDIR}/${PN}"

do_after_patch() {
	cp "${COPYSOURCE}/aesys_2319a.dts" "${WORKDIR}/git/arch/arm64/boot/dts/freescale"
}

addtask after_patch after do_patch before do_configure