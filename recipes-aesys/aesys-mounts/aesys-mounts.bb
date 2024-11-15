SUMMARY = "Custom Aesys systemd mount unit files"
DESCRIPTION = "Adds custom Aesys systemd mount unit files to image"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r1"

SRC_URI =  " \
    file://boot.mount \
"

FILES:${PN} += " \
    ${systemd_unitdir}/system/boot.mount \
"

do_install () {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/boot.mount ${D}${systemd_unitdir}/system
}

NATIVE_SYSTEMD_SUPPORT = "1"
SYSTEMD_PACKAGES = "${PN}"

inherit allarch systemd