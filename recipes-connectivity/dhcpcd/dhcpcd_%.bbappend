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

    echo "profile fallback_eth0" >> ${S}/src/dhcpcd.conf
    echo "static ip_address=192.168.1.1/24" >> ${S}/src/dhcpcd.conf
    echo "static routers=192.168.1.1" >> ${S}/src/dhcpcd.conf
    echo >> ${S}/src/dhcpcd.conf

    echo "interface eth0" >> ${S}/src/dhcpcd.conf
    echo "fallback fallback_eth0" >> ${S}/src/dhcpcd.conf
    echo >> ${S}/src/dhcpcd.conf
}