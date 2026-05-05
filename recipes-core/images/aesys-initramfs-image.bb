SUMMARY = "Aesys INITRAMFS image"

# Add aesys packages
AESYS_MACHINE_BASED_PACKAGES="aesys-hw-wdog"
AESYS_MACHINE_BASED_PACKAGES:genericx86-64=""

PACKAGE_INSTALL = "${AESYS_MACHINE_BASED_PACKAGES} ${VIRTUAL-RUNTIME_base-utils} util-linux-lsblk udev base-passwd openssl openssl-bin busybox unionfs-fuse e2fsprogs e2fsprogs-e2fsck e2fsprogs-mke2fs e2fsprogs-resize2fs parted dosfstools aufs-util aesys-initramfs-init"

# Do not pollute the initrd image with rootfs features
IMAGE_FEATURES = ""

export IMAGE_BASENAME = "${MLPREFIX}aesys-initramfs"

# Don't allow the initramfs to contain a kernel
PACKAGE_EXCLUDE = "kernel-image-*"

IMAGE_NAME_SUFFIX ?= ""
IMAGE_LINGUAS = ""

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

IMAGE_LINK_NAME = "initramfs"
INITRAMFS_FSTYPES += " cpio.gz.u-boot "
IMAGE_FSTYPES = "${INITRAMFS_FSTYPES}"

inherit core-image

IMAGE_ROOTFS_SIZE = "8192"
IMAGE_ROOTFS_EXTRA_SPACE = "0"

# Use the same restriction as initramfs-module-install
COMPATIBLE_HOST = '(x86_64.*|i.86.*|arm.*|aarch64.*)-(linux.*|freebsd.*)'


