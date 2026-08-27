FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

RDEPENDS:${PN} += "bash"

SRC_URI += " \
   file://aesys.app.conf \
"

FILES:${PN} += " \
    ${sysconfdir}/dbus-1/system.d/aesys.app.conf \
"

do_install:append(){
    
    install -d ${D}${sysconfdir}/dbus-1/
    install -d ${D}${sysconfdir}/dbus-1/system.d/

    install -d ${D}${sysconfdir}/dbus-1/system.d/
    install -m 644 ${WORKDIR}/aesys.app.conf ${D}${sysconfdir}/dbus-1/system.d/aesys.app.conf
}