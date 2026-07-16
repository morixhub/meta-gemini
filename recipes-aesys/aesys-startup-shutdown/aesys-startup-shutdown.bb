SUMMARY = "Commands to be executed at system startup"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS:${PN} += "bash"

SRC_URI = " \
    file://firstinit.png \
    file://aesys-startup.sh \
    file://aesys-shutdown.sh \
    file://aesys-startup-shutdown.service \
"

S = "${UNPACKDIR}"

FILES:${PN} += " \
    ${sbindir}/firstinit.png \
    ${sbindir}/aesys-startup.sh \
    ${sbindir}/aesys-shutdown.sh \
    ${systemd_unitdir}/system/aesys-startup-shutdown.service \
"

do_install() {
    install -d ${D}/${sbindir}
    install -m 0755 ${S}/firstinit.png ${D}${sbindir}
    install -m 0755 ${S}/aesys-startup.sh ${D}${sbindir}
    install -m 0755 ${S}/aesys-shutdown.sh ${D}${sbindir}

    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${S}/aesys-startup-shutdown.service ${D}${systemd_unitdir}/system
}

NATIVE_SYSTEMD_SUPPORT = "1"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "aesys-startup-shutdown.service"

inherit allarch systemd
