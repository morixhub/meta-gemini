SUMMARY = "Ensure that DHCP client is triggered if an interface acquire a fallback IP address"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS:${PN} += "bash"

SRC_URI += " \
    file://dhcp-recheck.sh \
    file://dhcp-recheck.service \
    file://dhcp-recheck.timer \
    file://broadcast-dhcp-discover-from-any.nse \
"

FILES:${PN} += " \
    ${sbindir}/dhcp-recheck.sh \
    ${systemd_unitdir}/system/dhcp-recheck.service \
    ${systemd_unitdir}/system/dhcp-recheck.timer \
    ${datadir}/nmap/scripts/broadcast-dhcp-discover-from-any.nse \
"

do_install() {
    install -d ${D}/${sbindir}
    install -m 0755 ${UNPACKDIR}/dhcp-recheck.sh ${D}${sbindir}

    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${UNPACKDIR}/dhcp-recheck.service ${D}${systemd_unitdir}/system
    install -m 0644 ${UNPACKDIR}/dhcp-recheck.timer ${D}${systemd_unitdir}/system

    install -d ${D}${datadir}/nmap/scripts
    install -m 0644 ${UNPACKDIR}/broadcast-dhcp-discover-from-any.nse ${D}${datadir}/nmap/scripts
}

NATIVE_SYSTEMD_SUPPORT = "1"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "\
    dhcp-recheck.service \
    dhcp-recheck.timer \
"

inherit systemd
