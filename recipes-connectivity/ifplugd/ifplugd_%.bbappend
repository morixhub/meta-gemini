FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

RDEPENDS:${PN} += "bash"

SRC_URI += " \
   file://ifplugd.action \
   file://ifupdown \
   file://ifplugd.sh \
   file://ifplugd.service \
"

FILES:${PN} += " \
    ${sysconfdir}/ifplugd/ifplugd.action \
    ${sysconfdir}/ifplugd/action.d/ifupdown \
    ${sbindir}/ifplugd.sh \
    ${systemd_unitdir}/system/ifplugd.service \
"

do_install:append(){

    # Install action files
    install -d ${D}/${sysconfdir}/ifplugd
    install -d ${D}/${sysconfdir}/ifplugd/action.d
    install -m 0755 ${WORKDIR}/ifplugd.action ${D}${sysconfdir}/ifplugd
    install -m 0755 ${WORKDIR}/ifupdown ${D}${sysconfdir}/ifplugd/action.d

    # Install systemd service script
    install -d ${D}/${sbindir}
    install -m 0755 ${WORKDIR}/ifplugd.sh ${D}${sbindir}

    # Install systemd service
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/ifplugd.service ${D}${systemd_unitdir}/system

    # Modify configuration for supporting wired0 and wired1
    sed -i -e 's|^.*INTERFACES=.*|INTERFACES="wired0 wired1"|' ${D}${sysconfdir}/ifplugd/ifplugd.conf
}

inherit systemd

# systemd configuration
NATIVE_SYSTEMD_SUPPORT = "1"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "\
    ifplugd.service \
"

# Enable ifplugd by default
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# Inhibit the update-rc.d class, so that we are not going to have sys-v-init script in /etc/init.d
INHIBIT_UPDATERCD_BBCLASS = "1"