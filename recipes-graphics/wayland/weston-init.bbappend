FILES:${PN} += "\
    ${sysconfdir}/vnc/keys \
"

do_install:append(){

    # Adjust weston.ini for enabling screen-share through vnc-backend
    sed -i -e "/^\[core\]/a modules=screen-share.so" ${D}${sysconfdir}/xdg/weston/weston.ini
    sed -i -e "s|^command=${bindir}/weston .*|command=${bindir}/weston --backend=vnc-backend.so --vnc-tls-cert=/etc/vnc/keys/tls.crt --vnc-tls-key=/etc/vnc/keys/tls.key --shell=fullscreen-shell.so --no-config|" ${D}${sysconfdir}/xdg/weston/weston.ini
    sed -i -e "s|^#start-on-startup=true|start-on-startup=true|" ${D}${sysconfdir}/xdg/weston/weston.ini

    # Disable the virtual keyboard
    echo "" >> ${D}${sysconfdir}/xdg/weston/weston.ini
    echo "" >> ${D}${sysconfdir}/xdg/weston/weston.ini
    echo "# Purposely set an invalid path to weston keyboard, for disabling it completely" >> ${D}${sysconfdir}/xdg/weston/weston.ini
    echo "[input-method]" >> ${D}${sysconfdir}/xdg/weston/weston.ini
    echo "path=/invalid-path/weston-keyboard" >> ${D}${sysconfdir}/xdg/weston/weston.ini

    ## Prepare directory for VNC keys
    install -m 0755 -d ${D}${sysconfdir}/vnc/keys/
    chown weston:weston ${D}${sysconfdir}/vnc/keys/
}

