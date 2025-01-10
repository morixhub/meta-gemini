FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PACKAGECONFIG:append = " vnc"

SRC_URI += " \
    file://weston-remote-access \
"

FILES:${PN} += "\
    ${sysconfdir}/pam.d/weston-remote-access \
"

do_install:append(){

    install -D -p -m 0644 ${WORKDIR}/weston-remote-access ${D}${sysconfdir}/pam.d/weston-remote-access
}