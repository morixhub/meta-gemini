do_deploy:append:genericx86-64() {
    if [ -f ${B}/u-boot-payload.efi ]; then
        install -d ${DEPLOYDIR}
        install -m 0644 ${B}/u-boot-payload.efi ${DEPLOYDIR}/u-boot-payload.efi
    fi
}

UBOOT_SREC:genericx86-64 = "u-boot-payload.efi"
UBOOT_BIN:genericx86-64 = "u-boot-payload.efi"
