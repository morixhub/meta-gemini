SUMMARY = "HW watchdog management"
DESCRIPTION = "Adds the utilities for managing the HW watchdog"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r1"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

RDEPENDS:${PN} += "bash"

SRC_URI = " \
    file://aesys-2409a-hw-wdog-toggle.sh \
    file://aesys-2409a-hw-wdog-status.sh \
    file://aesys-2409a-hw-wdog-refresh.sh \
    file://aesys-2414-hw-wdog-toggle.sh \
    file://aesys-2414-hw-wdog-status.sh \
    file://aesys-2414-hw-wdog-refresh.sh \
    file://aesys-2602a-hw-wdog-toggle.sh \
    file://aesys-2602a-hw-wdog-status.sh \
    file://aesys-2602a-hw-wdog-refresh.sh \
"

FILES:${PN}:aesys-2409a += " \
    ${bindir}/hw-wdog-toggle.sh \
    ${bindir}/hw-wdog-status.sh \
    ${bindir}/hw-wdog-refresh.sh \
"

do_install:aesys-2409a () {
    install -d ${D}${bindir}
    install -m 0544 ${WORKDIR}/aesys-2409a-hw-wdog-toggle.sh ${D}${bindir}/hw-wdog-toggle.sh
    install -m 0544 ${WORKDIR}/aesys-2409a-hw-wdog-status.sh ${D}${bindir}/hw-wdog-status.sh
    install -m 0544 ${WORKDIR}/aesys-2409a-hw-wdog-refresh.sh ${D}${bindir}/hw-wdog-refresh.sh
}

FILES:${PN}:aesys-2414 += " \
    ${bindir}/hw-wdog-toggle.sh \
    ${bindir}/hw-wdog-status.sh \
    ${bindir}/hw-wdog-refresh.sh \
"

do_install:aesys-2414 () {
    install -d ${D}${bindir}
    install -m 0544 ${WORKDIR}/aesys-2414-hw-wdog-toggle.sh ${D}${bindir}/hw-wdog-toggle.sh
    install -m 0544 ${WORKDIR}/aesys-2414-hw-wdog-status.sh ${D}${bindir}/hw-wdog-status.sh
    install -m 0544 ${WORKDIR}/aesys-2414-hw-wdog-refresh.sh ${D}${bindir}/hw-wdog-refresh.sh
}

FILES:${PN}:aesys-2414-2g += " \
    ${bindir}/hw-wdog-toggle.sh \
    ${bindir}/hw-wdog-status.sh \
    ${bindir}/hw-wdog-refresh.sh \
"

do_install:aesys-2414-2g () {
    install -d ${D}${bindir}
    install -m 0544 ${WORKDIR}/aesys-2414-hw-wdog-toggle.sh ${D}${bindir}/hw-wdog-toggle.sh
    install -m 0544 ${WORKDIR}/aesys-2414-hw-wdog-status.sh ${D}${bindir}/hw-wdog-status.sh
    install -m 0544 ${WORKDIR}/aesys-2414-hw-wdog-refresh.sh ${D}${bindir}/hw-wdog-refresh.sh
}

FILES:${PN}:aesys-2602a += " \
    ${bindir}/hw-wdog-toggle.sh \
    ${bindir}/hw-wdog-status.sh \
    ${bindir}/hw-wdog-refresh.sh \
"

do_install:aesys-2602a () {
    install -d ${D}${bindir}
    install -m 0544 ${WORKDIR}/aesys-2602a-hw-wdog-toggle.sh ${D}${bindir}/hw-wdog-toggle.sh
    install -m 0544 ${WORKDIR}/aesys-2602a-hw-wdog-status.sh ${D}${bindir}/hw-wdog-status.sh
    install -m 0544 ${WORKDIR}/aesys-2602a-hw-wdog-refresh.sh ${D}${bindir}/hw-wdog-refresh.sh
}


