SUMMARY = "System operating versioning"
DESCRIPTION = "Adds the ID of the operating system"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r1"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    file://os-ver \
"

FILES:${PN} += " \
    ${sysconfdir}/os-ver \
"

do_install() {
    install -d ${D}${sysconfdir}
    install -m 0444 ${WORKDIR}/os-ver ${D}${sysconfdir}/os-ver

    # Provide hash link (required by OpenSSL for finding certificates)
    ln -s -r ${D}${sysconfdir}/os-ver ${D}${sysconfdir}/so-ver
}

