do_install:append() {
    install -d ${D}${bindir}
    ln -rs ${D}${bindir}/xml ${D}${bindir}/xmlstarlet
}
