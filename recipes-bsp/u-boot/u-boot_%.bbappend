FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " file://Aesys-UBoot-Config-Fragment.cfg"
SRC_URI += " file://0007-Introduced-PXEQuick-Option-And-ARP-Timeout-Configurability.patch"
SRC_URI += " file://0008-PXE-Resolve-EnvVariables-In-Kernel-Config-Name.patch"
SRC_URI += " file://0009-Minimized-UBoot-Warning-Messages.patch"

do_deploy:append:genericx86-64() {
    if [ -f ${B}/u-boot-payload.efi ]; then
        install -d ${DEPLOYDIR}
        install -m 0644 ${B}/u-boot-payload.efi ${DEPLOYDIR}/u-boot-payload.efi
    fi
}

UBOOT_SREC:genericx86-64 = "u-boot-payload.efi"
UBOOT_BIN:genericx86-64 = "u-boot-payload.efi"

# Copy additional stuff to working copy after patching
COPYSOURCE := "${THISDIR}/${PN}"
do_after_patch() {

	# COMMON
	cp "${COPYSOURCE}/efi-x86_payload.h" "${WORKDIR}/git/include/configs/"
    cp "${COPYSOURCE}/gemini_env.h" "${WORKDIR}/git/include/configs/"
}

addtask after_patch after do_patch before do_configure


