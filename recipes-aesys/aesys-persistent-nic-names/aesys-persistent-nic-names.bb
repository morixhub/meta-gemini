SUMMARY = "Persistent NIC name"
DESCRIPTION = "Machine-specific configuration files for persistent NIC naming"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r1"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI =  " \
    file://aesys-2319a_70-wired0.link \
    file://aesys-2319a_71-wired1.link \
    file://aesys-2409_70-wired0.link \
    file://aesys-2414_70-wired0.link \
    file://aesys-2414_71-wired1.link \
    file://aesys-2602_70-wired0.link \
    file://aesys-2602_71-wired1.link \
    file://aesys-2522_70-wired0.link \
    file://aesys-2522_71-wired1.link \
"

FILES:${PN} += " \
    ${systemd_unitdir}/network/70-wired0.link \
    ${systemd_unitdir}/network/71-wired1.link \
"

do_install:append:aesys-2319a () {
    install -d ${D}${systemd_unitdir}/network/
    install -m 0644 ${WORKDIR}/aesys-2319a_70-wired0.link ${D}${systemd_unitdir}/network/70-wired0.link
    install -m 0644 ${WORKDIR}/aesys-2319a_71-wired1.link ${D}${systemd_unitdir}/network/71-wired1.link
}

do_install:append:aesys-2409 () {
    install -d ${D}${systemd_unitdir}/network/
    install -m 0644 ${WORKDIR}/aesys-2409_70-wired0.link ${D}${systemd_unitdir}/network/70-wired0.link
}

do_install:append:aesys-2414 () {
    install -d ${D}${systemd_unitdir}/network/
    install -m 0644 ${WORKDIR}/aesys-2414_70-wired0.link ${D}${systemd_unitdir}/network/70-wired0.link
    install -m 0644 ${WORKDIR}/aesys-2414_71-wired1.link ${D}${systemd_unitdir}/network/71-wired1.link
}

do_install:append:aesys-2414-2g () {
    install -d ${D}${systemd_unitdir}/network/
    install -m 0644 ${WORKDIR}/aesys-2414_70-wired0.link ${D}${systemd_unitdir}/network/70-wired0.link
    install -m 0644 ${WORKDIR}/aesys-2414_71-wired1.link ${D}${systemd_unitdir}/network/71-wired1.link
}

do_install:append:aesys-2602 () {
    install -d ${D}${systemd_unitdir}/network/
    install -m 0644 ${WORKDIR}/aesys-2602_70-wired0.link ${D}${systemd_unitdir}/network/70-wired0.link
    install -m 0644 ${WORKDIR}/aesys-2602_71-wired1.link ${D}${systemd_unitdir}/network/71-wired1.link
}

do_install:append:aesys-2522 () {
    install -d ${D}${systemd_unitdir}/network/
    install -m 0644 ${WORKDIR}/aesys-2522_70-wired0.link ${D}${systemd_unitdir}/network/70-wired0.link
    install -m 0644 ${WORKDIR}/aesys-2522_71-wired1.link ${D}${systemd_unitdir}/network/71-wired1.link
}

PACKAGE_ARCH = "${MACHINE_ARCH}"


