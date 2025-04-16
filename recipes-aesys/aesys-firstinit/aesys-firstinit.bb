SUMMARY = "Initial boot resize partition script"
DESCRIPTION = "Script to resize the data partition at first boot init, started as a systemd service which removes itself once finished"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r1"

RDEPENDS:${PN} += "parted"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI =  " \
    file://aesys-firstinit.sh \
    file://aesys-firstinit.service \
"

FILES:${PN} += " \
    ${sbindir}/aesys-firstinit.sh \
    ${systemd_unitdir}/system/aesys-firstinit.service \
"

do_install () {
    install -d ${D}/${sbindir}
    install -m 0755 ${WORKDIR}/aesys-firstinit.sh ${D}${sbindir}

    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/aesys-firstinit.service ${D}${systemd_unitdir}/system
}

NATIVE_SYSTEMD_SUPPORT = "1"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "aesys-firstinit.service"

inherit allarch systemd