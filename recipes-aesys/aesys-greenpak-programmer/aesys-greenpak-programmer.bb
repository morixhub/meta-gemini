DESCRIPTION = "Greenpak programmer"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRCREV = "a5a69f29e18f24d4e2685563b296d22fe043f0ca"

SRC_URI = "git://github.com/morixhub/greenpak-programmer.git;protocol=https;branch=main"
SRC_URI[sha256sum] = "c53e263b4d16473373c5b7f19a5ccfdec0fd9603b13b5760a8129c38ba3dc7a3"


FILES:${PN} += " \
    ${bindir}/greenpak-programmer \
"

S = "${WORKDIR}/git"

DEPENDS += " i2c-tools "

do_compile () {
    oe_runmake
}

do_install () {
    install -d ${D}${bindir}
    install -m 0755 greenpak-programmer ${D}${bindir}/
}
