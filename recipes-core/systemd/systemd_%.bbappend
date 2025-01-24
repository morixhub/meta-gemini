do_configure:append() {

    # Disable systemd-timesyncd service by default (NTP sync is normally handled at application level)
    sed -i -e "s/enable systemd-timesyncd.service/disable systemd-timesyncd.service/g" ${S}/presets/90-systemd.preset
}


do_install:append(){

    # Adjust journald.conf for OS hardenind purposes
    echo "ForwardToSyslog=yes" >> ${D}${sysconfdir}/systemd/journald.conf
    echo "Compress=yes" >> ${D}${sysconfdir}/systemd/journald.conf
    echo "Storage=persistent" >> ${D}${sysconfdir}/systemd/journald.conf
}

