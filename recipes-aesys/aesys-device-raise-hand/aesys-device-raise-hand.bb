SUMMARY = "Device raise-hand service"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS:${PN} += "bash"

SRC_URI = " \
    file://raise-hand.sh \
    file://aesys-device-raise-hand.service \
"

FILES:${PN} += " \
    ${sbindir}/raise-hand.sh \
    ${systemd_unitdir}/system/aesys-device-raise-hand.service \
"

S = "${UNPACKDIR}"

do_install() {
    install -d ${D}/${sbindir}
    install -m 0755 ${S}/raise-hand.sh ${D}${sbindir}

    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${S}/aesys-device-raise-hand.service ${D}${systemd_unitdir}/system
}

NATIVE_SYSTEMD_SUPPORT = "1"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "aesys-device-raise-hand.service"

inherit allarch systemd
