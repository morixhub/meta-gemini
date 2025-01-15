do_install:append(){

    # Adjust journald.conf for OS hardenind purposes
    echo "ForwardToSyslog=yes" >> ${D}${sysconfdir}/systemd/journald.conf
    echo "Compress=yes" >> ${D}${sysconfdir}/systemd/journald.conf
    echo "Storage=persistent" >> ${D}${sysconfdir}/systemd/journald.conf
}