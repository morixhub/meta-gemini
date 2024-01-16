#FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
#SRC_URI += " file://0001-Imported-DTS-from-i.MX-Config-Tool.patch"

COPYSOURCE := "${THISDIR}/${PN}"

do_after_patch() {
	echo "THISDIR is" ${THISDIR}
	echo "PN is" ${PN}
	echo "BPN is" ${BPN}
	echo "PV is" ${PV}
	echo "COPYSOURCE is" ${COPYSOURCE}

	cp "${COPYSOURCE}/lpddr4_timing.c" "${WORKDIR}/git/board/freescale/imx8mp_evk"
}

addtask after_patch after do_patch before do_configure

