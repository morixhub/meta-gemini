FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " file://fragment.cfg;subdir=busybox-1.36.1"
SRC_URI += " file://0001-BusyBox-stty-Add-RS485-config-options.patch"

