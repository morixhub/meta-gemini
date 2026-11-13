FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS:append = " aml"

PACKAGECONFIG:append = " vnc"
PACKAGECONFIG:append = " lcms"

SRC_URI += " \
    file://weston-remote-access \
    file://0001-screenshoter_to_stdout.patch \
    file://0002-image_full_screen.patch \
"

#//!! ATTENTION: patch 0003-force-color-transforms-format.patch has to be adapted to wrynose and it is not applied!!!

FILES:${PN} += "\
    ${sysconfdir}/pam.d/weston-remote-access \
"

do_install:append(){

    # Install PAM configuration for weston
    install -D -p -m 0644 ${UNPACKDIR}/weston-remote-access ${D}${sysconfdir}/pam.d/weston-remote-access

}