DESCRIPTION = "Allows to customize the fstab"
PR = "r0"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
   file://fstab \
"

do_install:append(){
   install -m 0644 ${WORKDIR}/fstab ${D}${sysconfdir}/

   # Adjust rsyslog.conf for OS hardenind purposes
   sed -i -e "s|^umask 022|umask 027|" ${D}${sysconfdir}/profile
}