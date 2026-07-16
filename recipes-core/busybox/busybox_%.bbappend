FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " file://fragment.cfg;subdir=busybox-1.37.0"
SRC_URI += " file://0001-BusyBox-stty-Add-RS485-config-options.patch"
SRC_URI += " file://0002-BusyBox-stty-Fix.patch"


