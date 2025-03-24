do_install:append() {
    install -d ${D}/${bindir}
    install -m 0644 ${D}${bindir}/base64.${BPN} ${D}${bindir}/base64
}