SUMMARY = "Automount automation"
DESCRIPTION = "Automation requested for automounting USB drives"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r1"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    file://automount.rules \
    file://mount.sh \
    file://mount.ignorelist \
"

S = "${UNPACKDIR}"

MOUNT_BASE = "/run/media"

do_install() {
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${S}/automount.rules ${D}${sysconfdir}/udev/rules.d/automount.rules

    install -d ${D}${sysconfdir}/udev/mount.ignorelist.d
    install -m 0644 ${S}/mount.ignorelist ${D}${sysconfdir}/udev/

    install -d ${D}${sysconfdir}/udev/scripts/

    install -m 0755 ${S}/mount.sh ${D}${sysconfdir}/udev/scripts/mount.sh
    sed -i 's|@systemd_unitdir@|${systemd_unitdir}|g' ${D}${sysconfdir}/udev/scripts/mount.sh
    sed -i 's|@base_sbindir@|${base_sbindir}|g' ${D}${sysconfdir}/udev/scripts/mount.sh
    sed -i 's|@MOUNT_BASE@|${MOUNT_BASE}|g' ${D}${sysconfdir}/udev/scripts/mount.sh
}

pkg_postinst:${PN} () {
    if [ -e $D${systemd_unitdir}/system/systemd-udevd.service ]; then
        sed -i "/\[Service\]/aMountFlags=shared" $D${systemd_unitdir}/system/systemd-udevd.service
    fi
}

pkg_postrm:${PN} () {
    if [ -e $D${systemd_unitdir}/system/systemd-udevd.service ]; then
        sed -i "/MountFlags=shared/d" $D${systemd_unitdir}/system/systemd-udevd.service
    fi
}

RDEPENDS:${PN} = "udev util-linux-blkid ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'util-linux-lsblk', '', d)}"
CONFFILES:${PN} = "${sysconfdir}/udev/mount.ignorelist"

