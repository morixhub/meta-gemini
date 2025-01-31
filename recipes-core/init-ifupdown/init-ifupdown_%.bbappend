FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
   file://interfaces \
"

FILES:${PN} += " \
    ${sysconfdir}/network/interfaces \
"

do_install:append(){
    
    install -d ${D}${sysconfdir}/network
    install -d ${D}${sysconfdir}/network/interfaces.d
    install -m 0644 ${WORKDIR}/interfaces ${D}${sysconfdir}/network/interfaces
}