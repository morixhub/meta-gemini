SUMMARY = "Configuration files for moal driver"
SECTION = "kernel/modules"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://moal_params.conf \
    file://moal_startup.conf \
"

inherit allarch

do_install() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        install -d ${D}${sysconfdir}/modules-load.d
        install -m 0644 ${WORKDIR}/moal_startup.conf ${D}${sysconfdir}/modules-load.d/moal.conf

        install -d ${D}${sysconfdir}/modprobe.d
        install -m 0644 ${WORKDIR}/moal_params.conf ${D}${sysconfdir}/modprobe.d/moal.conf
    fi
}
