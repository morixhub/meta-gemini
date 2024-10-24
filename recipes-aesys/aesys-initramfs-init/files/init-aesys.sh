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

# Mount aux filesystems
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs dev /dev

# Wait for block device
if [ ! -b /dev/mmcblk1p1 ] || [ ! -b /dev/mmcblk1p2 ] || [ ! -b /dev/mmcblk1p3 ] || [ ! -b /dev/mmcblk1p4 ]; then
	do_log "Waiting for block device..." ;
	sleep 1 ;
fi

# Mount root file system
mount -t ext4 -o ro /dev/mmcblk1p2 /rootfs

# Check rootfs suitability
CHECK=0
while [ $CHECK -eq 0 ];
do
	if [ ! -d /rootfs/boot ] || [ ! -d /rootfs/var ] || [ ! -d /rootfs/data ]; then
		do_log "Root file-system is not suitable; missing some requested folder" ;
		do_panic ;
	else
		CHECK=1 ;
	fi
done

# Mount relevant file systems
mount -t vfat -o ro /dev/mmcblk1p1 /rootfs/boot
mount -t ext4 -o ro /dev/mmcblk1p3 /rootfs/var
mount -t ext4 -o ro /dev/mmcblk1p4 /rootfs/data

# Determine if shell is requested
SHELL_REQUESTED=0
if [ -e /rootfs/var/aesys/shell.requested ]; then
	SHELL_REQUESTED=1 ;
fi

# Determine if overlayroot is requested
OVERLAYROOT_ENABLED=1
if [ -e /rootfs/var/aesys/overlayroot.disabled ]; then
	OVERLAYROOT_ENABLED=0 ;
fi

# Mount temporary filesystems
mount -t tmpfs -o mode=0755,nodev,nosuid,strictatime tmpfs /initram

if [ $OVERLAYROOT_ENABLED -eq 1 ]; then

	mkdir -p /overlayroot
	mkdir -p /overlay

	mount -t tmpfs tmpfs /overlay ;
fi

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
	if [ ! -e /rootfs/data/securefs.data ] || [ ! -e /rootfs/data/securefs.data.sig ]; then
		if [ -e /rootfs/var/aesys/securefs.skip ]; then
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
		openssl dgst -sha256 -keyform PEM -verify /initram/securefs.publickey.pem -signature /rootfs/data/securefs.data.sig /rootfs/data/securefs.data ;

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
		cat /rootfs/data/securefs.data | chroot /rootfs sha256sum -c -s ;

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
umount /rootfs/boot
umount /rootfs/var
umount /rootfs/data

# Enforce root overlay, if requested
if [ $OVERLAYROOT_ENABLED -eq 1 ]; then

	CHECK=0 ;
	while [ $CHECK -eq 0 ];
	do 
		# Log
		do_log "Enabling overlay on root filesystem..." ;

		# Prepare overlay 
		mkdir -p /overlay/lower ;
		mkdir -p /overlay/upper ;
		mkdir -p /overlay/work ;

		# Move rootfs mount point to overlay lower
		mount --move /rootfs /overlay/lower

		# Mount overlay
		mount -t overlay -o lowerdir=/overlay/lower,upperdir=/overlay/upper,workdir=/overlay/work overlay /overlayroot ;

		# Check the mount for being in place
		OVERLAY_VERIFICATION=`mount | grep "overlay on /overlayroot"` ;

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
	mkdir -p /overlayroot/initram
	mount --move /initram /overlayroot/initram

	mkdir -p /overlayroot/overlay
	mount --move /overlay /overlayroot/overlay

else

	# Log
	do_log "Overlay on root filesystem DISABLED! Root filesystem is R/W!" ;

	# Remount root filesystem R/W so that the system is completely "open"
	mount -o remount,rw /rootfs ;

	# Move temporary file systems to new root
	mkdir -p /rootfs/initram
	mount --move /initram /rootfs/initram

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
	exec switch_root /overlayroot /sbin/init ;
else
	exec switch_root /rootfs /sbin/init ;
fi
