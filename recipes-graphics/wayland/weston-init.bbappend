PACKAGECONFIG:append = " vnc"

FILES:${PN} += "\
    ${sysconfdir}/vnc/keys \
"

do_install:append(){

    # Adjust weston.ini for enabling screen-share through vnc-backend
    if [ "${@bb.utils.contains('PACKAGECONFIG', 'vnc', 'yes', 'no', d)}" = "yes" ]; then
        sed -i -e "/^\[core\]/a modules=screen-share.so" ${D}${sysconfdir}/xdg/weston/weston.ini
        sed -i -e "s|^command=${bindir}/weston .*|command=${bindir}/weston --backend=vnc-backend.so --vnc-tls-cert=/etc/vnc/keys/tls.crt --vnc-tls-key=/etc/vnc/keys/tls.key --shell=fullscreen-shell.so --no-config|" ${D}${sysconfdir}/xdg/weston/weston.ini
        sed -i -e "s|^#start-on-startup=true|start-on-startup=true|" ${D}${sysconfdir}/xdg/weston/weston.ini
    fi

    ## Prepare directory for VNC keys
    install -m 0755 -d ${D}${sysconfdir}/vnc/keys/
    chown weston:weston ${D}${sysconfdir}/vnc/keys/
}

