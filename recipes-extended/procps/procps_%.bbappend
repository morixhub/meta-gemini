do_install:append(){

    # Customization for OS hardening
    echo "fs.suid_dumpable = 0" >> ${D}${sysconfdir}/sysctl.conf
    echo "kernel.randomize_va_space = 2" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv4.ip_forward = 0" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv6.conf.all.forwarding = 0" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv4.conf.all.send_redirects = 0" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv4.conf.default.send_redirects = 0" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv4.conf.all.accept_source_route = 0" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv4.conf.default.accept_source_route = 0" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv6.conf.all.accept_source_route = 0" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv6.conf.default.accept_source_route = 0" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv4.conf.all.accept_redirects = 0" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv4.conf.default.accept_redirects = 0" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv6.conf.all.accept_redirects = 0" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv6.conf.default.accept_redirects = 0" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv4.conf.all.secure_redirects = 0" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv4.conf.default.secure_redirects = 0" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv4.conf.all.log_martians = 1" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv4.conf.default.log_martians = 1" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv4.icmp_ignore_bogus_error_responses = 1" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv6.conf.all.accept_ra = 1" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv6.conf.default.accept_ra = 1" >> ${D}${sysconfdir}/sysctl.conf
}