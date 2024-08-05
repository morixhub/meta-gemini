#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin

do_log() {
	echo "SecureFS:" $1 > /dev/kmsg
}

do_panic() {
	do_log "Error detected while securing root filesystem: entering console for debugging... Type ENTER to get the prompt" ;
	/bin/sh ;
}

do_mount_fs() {
	grep -q "$1" /proc/filesystems || return
	test -d "$2" || mkdir -p "$2"
	mount -t "$1" "$1" "$2"
}

# Log
do_log "Starting...";

# Prepare directories
mkdir -p /proc
mkdir -p /run
mkdir -p /secure
mkdir -p /boot
mkdir -p /rootfs

# Mount aux filesystems
mount -t proc proc /proc
do_mount_fs sysfs /sys
do_mount_fs debugfs /sys/kernel/debug
do_mount_fs devtmpfs /dev
do_mount_fs devpts /dev/pts
do_mount_fs tmpfs /dev/shm

# Wait for block device
if [ ! -b /dev/mmcblk1p1 ] || [ ! -b /dev/mmcblk1p2 ] || [ ! -b /dev/mmcblk1p3 ] || [ ! -b /dev/mmcblk1p4 ]; then
	do_log "Waiting for block device..." ;
	sleep 1 ;
fi

# Mount app filesystems
mount -t tmpfs tmpfs /run
mount -t tmpfs tmpfs /secure
mount -t vfat /dev/mmcblk1p1 /boot
mount -t ext4 /dev/mmcblk1p2 /rootfs

# Mount var/data partitions already in-place to rootfs
if [ ! -d /rootfs/var ]; then
	do_log "Creating rootfs var directory..." ;
	mkdir /rootfs/var ;
fi

if [ ! -d /rootfs/data ]; then
	do_log "Creating rootfs data directory..." ;
	mkdir /rootfs/data ;
fi

mount -t ext4 /dev/mmcblk1p3 /rootfs/var
mount -t ext4 /dev/mmcblk1p4 /rootfs/data

# Make APP signature key available to other applications
cp /securefs.publickey.pem /secure/securefs.publickey.pem

# Check public key availability
CHECK=0
while [ $CHECK -eq 0 ];
do
	if [ ! -e "/secure/securefs.publickey.pem" ]; then
		do_log "Public key for FS verification not available" ;
		do_panic ;
	else
		CHECK=1 ;
	fi
done

# Check secure FS required files
CHECK=0
while [ $CHECK -eq 0 ];
do
	if [ ! -e /rootfs/data/securefs.data ] || [ ! -e /rootfs/data/securefs.data.sig ]; then
		do_log "SecureFS files not available" ;
		do_panic ;
	else
		CHECK=1 ;
	fi
done

# Validate secure FS signature
CHECK=0
while [ $CHECK -eq 0 ];
do
	openssl dgst -sha256 -keyform PEM -verify /secure/securefs.publickey.pem -signature /rootfs/data/securefs.data.sig /rootfs/data/securefs.data

	if [ ! $? -eq 0 ]; then
		do_log "SecureFS signature verification FAILED!" ;
		do_panic ;
	else
		CHECK=1 ;
	fi
done

# Validate indexed files
CHECK=0
while [ $CHECK -eq 0 ];
do
	cat /rootfs/data/securefs.data | chroot /rootfs sha256sum --check --status

	if [ ! $? -eq 0 ]; then
		do_log "SecureFS files validation FAILED!" ;
		do_panic ;
	else
		CHECK=1 ;
	fi
done

# Log
do_log "Filesystem is secured OK"
do_log "Switching root..."

# Move existing mounts
if [ ! -d /rootfs/run ]; then
	do_log "Creating rootfs run directory..." ;
	mkdir /rootfs/run ;
fi

if [ ! -d /rootfs/secure ]; then
	do_log "Creating rootfs secure directory..." ;
	mkdir /rootfs/secure ;
fi

mount --move /run /rootfs/run
mount --move /secure /rootfs/secure

# Handover
do_log "Process completed"

exec switch_root /rootfs /sbin/init
