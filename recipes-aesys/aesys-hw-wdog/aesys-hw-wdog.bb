SUMMARY = "HW watchdog management"
DESCRIPTION = "Adds the utilities for managing the HW watchdog"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r1"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

RDEPENDS:${PN} += "bash"

SRC_URI = " \
    file://aesys-2414-hw-wdog-enable.sh \
    file://aesys-2414-hw-wdog-disable.sh \
    file://aesys-2414-hw-wdog-toggle.sh \
"

FILES:${PN}:aesys-2409a += " \
    ${bindir}/hw-wdog-enable.sh \
    ${bindir}/hw-wdog-disable.sh \
    ${bindir}/hw-wdog-toggle.sh \
"

do_install:aesys-2409a () {
    install -d ${D}${bindir}
    install -m 0544 ${WORKDIR}/aesys-2409a-hw-wdog-enable.sh ${D}${bindir}/hw-wdog-enable.sh
    install -m 0544 ${WORKDIR}/aesys-2409a-hw-wdog-disable.sh ${D}${bindir}/hw-wdog-disable.sh
    install -m 0544 ${WORKDIR}/aesys-2409a-hw-wdog-toggle.sh ${D}${bindir}/hw-wdog-toggle.sh
}

FILES:${PN}:aesys-2414 += " \
    ${bindir}/hw-wdog-enable.sh \
    ${bindir}/hw-wdog-disable.sh \
    ${bindir}/hw-wdog-toggle.sh \
"

do_install:aesys-2414 () {
    install -d ${D}${bindir}
    install -m 0544 ${WORKDIR}/aesys-2414-hw-wdog-enable.sh ${D}${bindir}/hw-wdog-enable.sh
    install -m 0544 ${WORKDIR}/aesys-2414-hw-wdog-disable.sh ${D}${bindir}/hw-wdog-disable.sh
    install -m 0544 ${WORKDIR}/aesys-2414-hw-wdog-toggle.sh ${D}${bindir}/hw-wdog-toggle.sh
}

FILES:${PN}:aesys-2414-2g += " \
    ${bindir}/hw-wdog-enable.sh \
    ${bindir}/hw-wdog-disable.sh \
    ${bindir}/hw-wdog-toggle.sh \
"

do_install:aesys-2414-2g () {
    install -d ${D}${bindir}
    install -m 0544 ${WORKDIR}/aesys-2414-hw-wdog-enable.sh ${D}${bindir}/hw-wdog-enable.sh
    install -m 0544 ${WORKDIR}/aesys-2414-hw-wdog-disable.sh ${D}${bindir}/hw-wdog-disable.sh
    install -m 0544 ${WORKDIR}/aesys-2414-hw-wdog-toggle.sh ${D}${bindir}/hw-wdog-toggle.sh
}


