SUMMARY = "Aesys INITRAMFS INIT recipe"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://init-aesys.sh"

FILES:${PN} += " /init "

do_install() {
        install -m 0755 ${WORKDIR}/init-aesys.sh ${D}/init
}

