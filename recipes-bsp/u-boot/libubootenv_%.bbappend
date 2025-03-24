do_install:append() {
    install -d ${D}/${sysconfdir}
    ln -s -r ${D}/initram/fw_env.config ${D}${sysconfdir}/fw_env.config
}