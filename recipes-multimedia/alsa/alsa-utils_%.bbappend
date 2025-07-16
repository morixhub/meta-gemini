do_install:append(){

    # Configure systemd's alsa-restore unit for saving mixer preferences to writable location
    sed -i -e "/^\[Service\]/a ExecStartPre=+/bin/mkdir -m 755 -p /data/varrw" ${D}${systemd_unitdir}/system/alsa-restore.service
    sed -i -e "s|^ExecStart=.*|ExecStart=-/usr/sbin/alsactl --file /data/varrw/asound.state --no-ucm restore|" ${D}${systemd_unitdir}/system/alsa-restore.service
    sed -i -e "s|^ExecStop=.*|ExecStop=-/usr/sbin/alsactl --file /data/varrw/asound.state --no-ucm store|" ${D}${systemd_unitdir}/system/alsa-restore.service
}