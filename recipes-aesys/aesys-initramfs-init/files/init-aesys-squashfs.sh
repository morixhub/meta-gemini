#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin

do_log() {
	echo "INITRAM:" $1 > /dev/kmsg
}

do_panic() {
	do_log "Error detected while securing root filesystem: entering console for debugging... Type ENTER to get the prompt" ;
	/bin/sh ;
}

# Log
do_log "Starting...";

# Prepare directories
mkdir -p /proc
mkdir -p /sys
mkdir -p /dev

mkdir -p /initram

mkdir -p /rootfs
mkdir -p /boot
mkdir -p /persist
mkdir -p /data

# Mount aux filesystems
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs dev /dev

# Wait for block device
if [ ! -b /dev/mmcblk1p1 ] || [ ! -b /dev/mmcblk1p2 ] || [ ! -b /dev/mmcblk1p3 ]; then
	do_log "Waiting for block device..." ;
	sleep 1 ;
fi

# Mount relevant file systems (everything can be read-only, except persist for obvious reasons)
mount -t vfat -o ro /dev/mmcblk1p1 /boot
mount -t ext4 -o ro /dev/mmcblk1p3 /data
mount -t ext4 -o rw /dev/mmcblk1p2 /persist

# Determine if shell is requested
SHELL_REQUESTED=0
if [ -e /boot/shell.requested ]; then
	SHELL_REQUESTED=1 ;
fi

# Determine if overlayroot is requested
OVERLAYROOT_ENABLED=1
if [ -e /boot/overlayroot.disabled ]; then
	OVERLAYROOT_ENABLED=0 ;
fi

# Mount initram filesystems
mount -t tmpfs -o mode=0755,nodev,nosuid,strictatime tmpfs /initram

# Ensure persist filesystem has requested folders
mkdir -p /persist/upper
mkdir -p /persist/work

# Mount root file system from squash
mount -t squashfs -o ro /boot/rootfs.squashfs /rootfs

# Prepare folders for overlaying
mkdir -p /overlay
mkdir -p /overlay/rootfs ;
mkdir -p /overlay/persist ;
mkdir -p /overlay/persist-merge ;
mkdir -p /overlay/ram ;
mkdir -p /overlay/ram-merge ;

# Move rootfs mount point to overlay lower
mount --move /rootfs /overlay/rootfs
mount --move /persist /overlay/persist

# Mount overlay on persist
mount -t overlay -o lowerdir=/overlay/rootfs,upperdir=/overlay/persist/upper,workdir=/overlay/persist/work overlay /overlay/persist-merge ;

# Move boot and data mount points over persist overlay
mkdir -p /overlay/persist-merge/boot
mount --move /boot /overlay/persist-merge/boot

mkdir -p /overlay/persist-merge/data
mount --move /data /overlay/persist-merge/data

# Make APP signature key available to other applications
cp /securefs.publickey.pem /initram/securefs.publickey.pem

# Check public key availability
CHECK=0
while [ $CHECK -eq 0 ];
do
	if [ ! -e "/initram/securefs.publickey.pem" ]; then
		do_log "Public key for FS verification not available" ;
		do_panic ;
	else
		CHECK=1 ;
	fi
done

# Check secure FS required files
SKIPVERIFY=0
CHECK=0
while [ $CHECK -eq 0 ];
do
	if [ ! -e /overlay/persist-merge/data/securefs.data ] || [ ! -e /overlay/persist-merge/data/securefs.data.sig ]; then
		if [ -e /overlay/persist-merge/boot/securefs.skip ]; then
			SKIPVERIFY=1 ;
			CHECK=1 ;
		else
			do_log "SecureFS files not available" ;
			do_panic ;
		fi
	else
		CHECK=1 ;
	fi
done

if [ $SKIPVERIFY -eq 0 ]; then

	# Validate secure FS signature
	CHECK=0 ;
	while [ $CHECK -eq 0 ];
	do
		openssl dgst -sha256 -keyform PEM -verify /initram/securefs.publickey.pem -signature /overlay/persist-merge/data/securefs.data.sig /overlay/persist-merge/data/securefs.data ;

		if [ ! $? -eq 0 ]; then
			do_log "SecureFS signature verification FAILED!" ;
			do_panic ;
		else
			CHECK=1 ;
		fi
	done

	# Validate indexed files
	CHECK=0 ;
	while [ $CHECK -eq 0 ];
	do
		cat /overlay/persist-merge/data/securefs.data | chroot /overlay/persist-merge sha256sum -c -s ;

		if [ ! $? -eq 0 ]; then
			do_log "SecureFS files validation FAILED!" ;
			do_panic ;
		else
			CHECK=1 ;
		fi
	done

	# Log
	do_log "Filesystem is secured OK" ;

else

	# Log
	do_log "Filesystem verification was skipped" ;

fi

# Log
do_log "Preparing to root switching..."

# Unmount file systems requested no more
umount /overlay/persist-merge/boot
umount /overlay/persist-merge/data

# Enforce root overlay, if requested
if [ $OVERLAYROOT_ENABLED -eq 1 ]; then

	# Create temporary filesystem
	mount -t tmpfs tmpfs /overlay/ram ;

	CHECK=0 ;
	while [ $CHECK -eq 0 ];
	do 
		# Log
		do_log "Enabling overlay on root filesystem..." ;

		# Prepare overlay 
		mkdir -p /overlay/ram/upper ;
		mkdir -p /overlay/ram/work ;

		# Mount overlay
		mount -t overlay -o lowerdir=/overlay/persist-merge,upperdir=/overlay/ram/upper,workdir=/overlay/ram/work overlay /overlay/ram-merge ;

		# Check the mount for being in place
		OVERLAY_VERIFICATION=`mount | grep "overlay on /overlay/ram-merge"` ;

		if [ -z "$OVERLAY_VERIFICATION" ]; then

			# Log
			do_log "Cannot enforce overlay on root filesystem!" ;
			do_panic ;

		else

			# Write a file on /initram for having a quick way for verifying at runtime if overlay is in place
			touch /initram/overlayroot.enforced

			CHECK=1;
		fi
	done

	# Move temporary file systems to new root
	mkdir -p /overlay/ram-merge/initram
	mount --move /initram /overlay/ram-merge/initram

	mkdir -p /overlay/ram-merge/overlay
	mount --move /overlay /overlay/ram-merge/overlay

else

	# Log
	do_log "Overlay on root filesystem DISABLED! Root filesystem is R/W!" ;

	# Move temporary file systems to new root
	mkdir -p /overlay/persist-merge/initram
	mount --move /initram /overlay/persist-merge/initram

fi

# Go to shell, if requested
if [ $SHELL_REQUESTED -eq 1 ]; then
	
	# Log
	do_log "Going to emergency shell due to request... Type ENTER to get the prompt" ;
	/bin/sh ;
fi

# Handover
do_log "Switching root..."

if [ $OVERLAYROOT_ENABLED -eq 1 ]; then
	exec switch_root /overlay/ram-merge /sbin/init ;
else
	exec switch_root /overlay/persist-merge /sbin/init ;
fi
