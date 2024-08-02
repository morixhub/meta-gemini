#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin

do_mount_fs() {
	grep -q "$1" /proc/filesystems || return
	test -d "$2" || mkdir -p "$2"
	mount -t "$1" "$1" "$2"
}

echo ">>> AESYS INIT START..."

# Prepare directories
mkdir -p /proc
mkdir -p /run
mkdir -p /secure
mkdir -p /boot
mkdir -p /realroot

# Mount aux filesystems
mount -t proc proc /proc
do_mount_fs sysfs /sys
do_mount_fs debugfs /sys/kernel/debug
do_mount_fs devtmpfs /dev
do_mount_fs devpts /dev/pts
do_mount_fs tmpfs /dev/shm

# Wait for block device
if [ ! -b /dev/mmcblk1p1 ] || [ ! -b /dev/mmcblk1p2 ]; then
	echo "Waiting for block device..." ;
	sleep 1 ;
fi

# Mount app filesystems
mount -t tmpfs tmpfs /run
mount -t tmpfs tmpfs /secure
mount -t vfat /dev/mmcblk1p1 /boot
mount -t ext4 /dev/mmcblk1p2 /realroot

# Fill with test data
echo "Hello, RUN!" > /run/hello
echo "Hello, SECURE!" > /secure/hello
echo "Hello, BOOT!" > /boot/hello
echo "Hello, ROOT!" > /realroot/hello

echo ">>> Switching to real root..."

# Move existing mounts
if [ ! -d /realroot/run ]; then
	echo "Creating realroot run directory..." ;
	mkdir /realroot/run ;
fi

if [ ! -d /realroot/secure ]; then
	echo "Creating realroot secure directory..." ;
	mkdir /realroot/secure ;
fi

mount --move /run /realroot/run
mount --move /secure /realroot/secure

# Handover
echo ">>> AESYS INIT END..."

exec switch_root /realroot /sbin/init