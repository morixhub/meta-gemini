FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PACKAGECONFIG:append = " vnc"

SRC_URI += " \
    file://weston-remote-access \
    file://0001-screenshoter_to_stdout.patch \
    file://0002-image_full_screen.patch \
"

FILES:${PN} += "\
    ${sysconfdir}/pam.d/weston-remote-access \
"

do_install:append(){

    # Install PAM configuration for weston
    install -D -p -m 0644 ${UNPACKDIR}/weston-remote-access ${D}${sysconfdir}/pam.d/weston-remote-access

}