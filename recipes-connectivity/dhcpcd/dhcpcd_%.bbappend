FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Disable dhcpcd by default (we do not want dhcpcd to run in manager mode, but only upon specific interface request)
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

RDEPENDS:${PN} += "bash"

SRC_URI += " \
    file://dhcpcd.enter-hook \
    file://dhcpcd.exit-hook \
"

FILES:${PN} += " \
    ${sysconfdir}/dhcpcd.enter-hook \
    ${sysconfdir}/dhcpcd.exit-hook \
"

do_configure:append() {

    # Customization
    echo >> ${S}/src/dhcpcd.conf
    echo "# AESYS customization" >> ${S}/src/dhcpcd.conf
    echo >> ${S}/src/dhcpcd.conf
    
    echo "hostname" >> echo >> ${S}/src/dhcpcd.conf
    echo >> ${S}/src/dhcpcd.conf

    echo "option ntp_servers" >> echo >> ${S}/src/dhcpcd.conf
    echo "option log_servers" >> echo >> ${S}/src/dhcpcd.conf
    echo >> ${S}/src/dhcpcd.conf

    echo "timeout 0" >> ${S}/src/dhcpcd.conf
    echo "reboot 60" >> ${S}/src/dhcpcd.conf
    echo >> ${S}/src/dhcpcd.conf

    echo "profile static_wired0" >> ${S}/src/dhcpcd.conf
    echo "static ip_address=192.168.1.1/24" >> ${S}/src/dhcpcd.conf
    echo "static routers=192.168.1.1" >> ${S}/src/dhcpcd.conf
    echo >> ${S}/src/dhcpcd.conf

    echo "interface wired0" >> ${S}/src/dhcpcd.conf
    echo "fallback static_wired0" >> ${S}/src/dhcpcd.conf
    echo >> ${S}/src/dhcpcd.conf

    echo "profile static_wired1" >> ${S}/src/dhcpcd.conf
    echo "static ip_address=192.168.2.1/24" >> ${S}/src/dhcpcd.conf
    echo "static routers=192.168.2.1" >> ${S}/src/dhcpcd.conf
    echo >> ${S}/src/dhcpcd.conf

    echo "interface wired1" >> ${S}/src/dhcpcd.conf
    echo "fallback static_wired1" >> ${S}/src/dhcpcd.conf
    echo >> ${S}/src/dhcpcd.conf
}

do_install:append(){

    install -d ${D}${sysconfdir}/
    install -m 0644 ${WORKDIR}/dhcpcd.enter-hook ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/dhcpcd.exit-hook ${D}${sysconfdir}
}