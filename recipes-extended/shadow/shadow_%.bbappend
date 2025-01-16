do_install:append() {

    # Customize login.defs for OS hardening purposes
    sed -i -e 's|^.*UMASK.*|UMASK 027|' ${D}${sysconfdir}/login.defs
    sed -i -e 's|^.*SU_WHEEL_ONLY.*|SU_WHEEL_ONLY yes|' ${D}${sysconfdir}/login.defs
}

