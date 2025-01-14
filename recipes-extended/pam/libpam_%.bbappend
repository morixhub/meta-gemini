do_install:append(){

    # Customization for OS hardening
    echo "root   hard   core    0" >> ${D}${sysconfdir}/security/limits.conf ;
}