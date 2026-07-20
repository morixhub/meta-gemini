FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

RDEPENDS:${PN} += "bash"

SRC_URI += " \
   file://aesys.tc.conf \
"

FILES:${PN} += " \
    ${sysconfdir}/dbus-1/system.d/aesys.tc.conf \
"

do_install:append(){
    
    install -d ${D}${sysconfdir}/dbus-1/
    install -d ${D}${sysconfdir}/dbus-1/system.d/

    install -d ${D}${sysconfdir}/dbus-1/system.d/
    install -m 644 ${WORKDIR}/aesys.tc.conf ${D}${sysconfdir}/dbus-1/system.d/aesys.tc.conf
}