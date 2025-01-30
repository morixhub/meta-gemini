do_configure:append() {

    # Disable systemd-networkd
    sed -i -e "s/enable systemd-networkd.service/disable systemd-networkd.service/g" ${S}/presets/90-systemd.preset
    sed -i -e "s/enable systemd-networkd-wait-online.service/disable systemd-networkd-wait-online.service/g" ${S}/presets/90-systemd.preset

    # Disable systemd-timesyncd service by default (NTP sync is normally handled at application level)
    sed -i -e "s/enable systemd-timesyncd.service/disable systemd-timesyncd.service/g" ${S}/presets/90-systemd.preset
}

do_install:append(){

    # Adjust journald.conf for OS hardenind purposes
    echo "ForwardToSyslog=yes" >> ${D}${sysconfdir}/systemd/journald.conf
    echo "Compress=yes" >> ${D}${sysconfdir}/systemd/journald.conf
    echo "Storage=persistent" >> ${D}${sysconfdir}/systemd/journald.conf
}

