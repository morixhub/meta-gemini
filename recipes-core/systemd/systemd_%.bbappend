do_configure:append() {

    # Disable systemd-networkd (we'd rather use /etc/network/interfaces)
    sed -i -e "s/enable systemd-networkd.service/disable systemd-networkd.service/g" ${S}/presets/90-systemd.preset
    sed -i -e "s/enable systemd-networkd-wait-online.service/disable systemd-networkd-wait-online.service/g" ${S}/presets/90-systemd.preset

    # Disable systemd-timesyncd service by default (NTP sync is normally handled at application level)
    sed -i -e "s/enable systemd-timesyncd.service/disable systemd-timesyncd.service/g" ${S}/presets/90-systemd.preset
}

do_install:append(){

    # Configure systemd-resolved for having a bind mount on /data for drop-in files
    install -m 0755 -d ${D}${sysconfdir}/systemd/resolved.conf.d/
    sed -i -e "/^\[Service\]/a ExecStartPre=-/bin/mkdir -m 755 -p /data/etcrw/systemd/resolved.conf.d /etc/systemd/resolved.conf.d" ${D}${systemd_unitdir}/system/systemd-resolved.service
    sed -i -e "/^\[Service\]/a BindPaths=-/data/etcrw/systemd/resolved.conf.d:/etc/systemd/resolved.conf.d" ${D}${systemd_unitdir}/system/systemd-resolved.service

    # Adjust journald.conf for OS hardening purposes
    echo "ForwardToSyslog=yes" >> ${D}${sysconfdir}/systemd/journald.conf
    echo "Compress=yes" >> ${D}${sysconfdir}/systemd/journald.conf
    echo "Storage=persistent" >> ${D}${sysconfdir}/systemd/journald.conf
}

