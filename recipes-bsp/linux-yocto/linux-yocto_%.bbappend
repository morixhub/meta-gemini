# Core patches
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " file://Aesys-Kernel-Config-Fragment.cfg"
SRC_URI += " file://0001-Fixed-SpiDev.patch"

# Remove the commit ID string from kernel version
# ATTENTION: the value of LINUX_VERSION_EXTENSION is not really important here: it is just for
# avoiding that FSL BSP generates something on its own; the correct kernel version is then
# set as part of the kernel configuration fragment
SCMVERSION="n"
LOCAL_VERSION=""
LINUX_VERSION_EXTENSION="+gemini"

# Manage kernel configuration fragments
DELTA_KERNEL_DEFCONFIG:append = "Aesys-Kernel-Config-Fragment.cfg"

# Copy additional stuff to working copy after patching
COPYSOURCE := "${THISDIR}/${PN}"

do_after_patch() {

	# GENERAL
	# Aesys logo
	cp "${COPYSOURCE}/linux_logo.png" "${STAGING_KERNEL_DIR}/drivers/video/logo"
	cp "${COPYSOURCE}/logo_linux_clut224.ppm" "${STAGING_KERNEL_DIR}/drivers/video/logo"
}

addtask after_patch after do_patch before do_configure
