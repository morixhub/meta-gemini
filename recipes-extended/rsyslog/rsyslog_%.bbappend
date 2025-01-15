do_install:append(){

    # Adjust rsyslog.conf for OS hardenind purposes
    sed -i -e "s|^#\$ModLoad imtcp.so .*|\$ModLoad imtcp.so|" ${D}${sysconfdir}/rsyslog.conf
    sed -i -e "s|^#\$InputTCPServerRun 514 .*|\$InputTCPServerRun 514|" ${D}${sysconfdir}/rsyslog.conf
}