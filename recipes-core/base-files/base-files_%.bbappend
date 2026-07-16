DESCRIPTION = "Allows customization of base files"
PR = "r0"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
   file://fstab \
   file://share/dot.bashrc \
"

do_install:append(){

    # Install fstab
    install -m 0644 ${UNPACKDIR}/fstab ${D}${sysconfdir}/

    # Install .bashrc
    install -m 0755 ${UNPACKDIR}/share/dot.bashrc ${D}${sysconfdir}/skel/.bashrc

    # Adjust /etc/profile for OS hardening purposes
    sed -i -e "s|^umask 022|umask 027|" ${D}${sysconfdir}/profile
    echo "TMOUT=900" >> ${D}${sysconfdir}/profile
}