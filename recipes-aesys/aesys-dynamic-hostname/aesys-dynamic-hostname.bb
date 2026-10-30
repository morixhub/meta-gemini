SUMMARY = "Dynamic host-name service"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS:${PN} += "bash"

SRC_URI = " \
    file://hostname-from-app.sh \
    file://aesys-dynamic-hostname.service \
"

FILES:${PN} += " \
    ${sbindir}/hostname-from-eeprom.sh \
    ${systemd_unitdir}/system/aesys-dynamic-hostname.service \
"

do_install() {
    install -d ${D}/${sbindir}
    install -m 0755 ${WORKDIR}/hostname-from-app.sh ${D}${sbindir}

    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/aesys-dynamic-hostname.service ${D}${systemd_unitdir}/system
}

NATIVE_SYSTEMD_SUPPORT = "1"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "aesys-dynamic-hostname.service"

inherit allarch systemd
