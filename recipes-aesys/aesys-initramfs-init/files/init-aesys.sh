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
do_log "Starting..."

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

# Locate boot device
# (it is necessary because the boot device changes booting from uSD or eMMC)
BOOT_DEVICE=`cat /proc/cmdline | sed -e 's/^.*root=//' -e 's/ .*$//' | sed 's/..$//'`

# Wait for block device
if [ ! -b ${BOOT_DEVICE}p1 ] || [ ! -b ${BOOT_DEVICE}p2 ]; then
	do_log "Waiting for block device..." ;
	sleep 1 ;
fi

# Mount relevant file systems
mount -t ext4 -o ro ${BOOT_DEVICE}p1 /boot
mount -t ext4 -o rw ${BOOT_DEVICE}p2 /data

# Enlarge data partition, if requested
PARTNUMBER=`mount | grep -e "^$BOOT_DEVICE" | grep /data | awk '{ print $1 }' | awk '{ print substr($0,length($0),1) }'`
BOOT_DEVICE_DEVNAME=${BOOT_DEVICE#"/dev/"} ;
DATA_SIZE=`lsblk -b | grep -i -e "${BOOT_DEVICE_DEVNAME}p${PARTNUMBER}" | awk ' { print $4 } '` ;

if [ ! -z $PARTNUMBER ]; then

	# Assume that /data has still to be resized if its size is less than 256MB
	if (( DATA_SIZE < 256 * 1024 * 1024 )); then

		# Resize data partition
		printf 'yes\n100%%' | parted ${BOOT_DEVICE} resizepart $PARTNUMBER ---pretend-input-tty ;

		# Resize file system
		resize2fs ${BOOT_DEVICE}p${PARTNUMBER} ;

		# Recalculate the size of /data
		DATA_SIZE=`lsblk -b | grep -i -e "${BOOT_DEVICE_DEVNAME}p${PARTNUMBER}" | awk ' { print $4 } '` ;
	fi
fi

# Create persist file in data, if not already there...
if [ ! -f /data/persist.bin ]; then

	# Determine max size (as the half of the available space on /data)
	MAX_SIZE=$(( DATA_SIZE / 2 )) ;
	
	# Create file
	dd if=/dev/null of=/data/persist.bin bs=1 seek=$MAX_SIZE ;

	# Loop-load the file
	LOOP_DEVICE=`losetup -f` ;
	losetup -f /data/persist.bin ;

	# Create ext4 filesystem
	mkfs.ext4 $LOOP_DEVICE ;

	# Release the loop
	losetup -d $LOOP_DEVICE ;
fi

# Mount the persist file system
mount -o loop /data/persist.bin /persist

# Mount initram filesystems
mount -t tmpfs -o mode=0755,nodev,nosuid,strictatime tmpfs /initram

# Ensure persist filesystem has folders requested for overlay
mkdir -p /persist/root
mkdir -p /persist/root/upper
mkdir -p /persist/root/work

mkdir -p /persist/var
mkdir -p /persist/var/upper
mkdir -p /persist/var/work

# Mount root file system from squash
mount -t squashfs -o ro /boot/rootfs.squashfs /rootfs

# Create a temporary mount on /overlay
# (so that it can act as a real mount point and can be moved around)
mkdir -p /overlay
mount -t tmpfs tmpfs /overlay

# Prepare folders for overlaying
mkdir -p /overlay/rootfs
mkdir -p /overlay/persist

mkdir -p /overlay-persist-root-merge
mkdir -p /overlay-persist-var-merge

# Move rootfs mount point to overlay lower
mount --move /rootfs /overlay/rootfs
mount --move /persist /overlay/persist

# Mount overlay on persist (root)
mount -t overlay -o lowerdir=/overlay/rootfs,upperdir=/overlay/persist/root/upper,workdir=/overlay/persist/root/work overlay /overlay-persist-root-merge ;

# Mount overlay on persist (var)
mount -t overlay -o lowerdir=/overlay/rootfs/var,upperdir=/overlay/persist/var/upper,workdir=/overlay/persist/var/work overlay /overlay-persist-var-merge ;

# Move persisted var overlay to persist overlay
mkdir -p /overlay-persist-root-merge/var
mount --move /overlay-persist-var-merge /overlay-persist-root-merge/var

# Move boot and data mount points over persist overlay
mkdir -p /overlay-root-merge/boot
mount --move /boot /overlay-persist-root-merge/boot

mkdir -p /overlay-persist-root-merge/data
mount --move /data /overlay-persist-root-merge/data

# Determine if shell is requested
SHELL_REQUESTED=0
if [ -e /overlay-persist-root-merge/var/aesys/shell.requested ]; then
	SHELL_REQUESTED=1 ;
fi

# Determine if overlayroot is requested
# Overlay can be explicitly disabled by file /var/aesys/overlayroot.disabled or
# silently implied by the first initialization procedure still pending
# (file /var/aesys/firstinit.pending still there)
OVERLAYROOT_ENABLED=1
if [ -e /overlay-persist-root-merge/var/aesys/overlayroot.disabled ] || [ -e /overlay-persist-root-merge/var/aesys/firstinit.pending ]; then
	OVERLAYROOT_ENABLED=0 ;
fi

# Make APP signature key available to other applications
# (do it anyway, even if the SecureFS is going to be skipped by request afterward)
if [ -e /securefs.publickey.pem ]; then
	cp /securefs.publickey.pem /initram/securefs.publickey.pem ;
fi

# Check secure FS required files
SKIPVERIFY=0
CHECK=0
while [ $CHECK -eq 0 ];
do
	if [ ! -e /initram/securefs.publickey.pem ] || [ ! -e /overlay-persist-root-merge/data/securefs.data ] || [ ! -e /overlay-persist-root-merge/data/securefs.data.sig ]; then
		if [ -e /overlay-persist-root-merge/var/aesys/securefs.skip ]; then
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
		openssl dgst -sha256 -keyform PEM -verify /initram/securefs.publickey.pem -signature /overlay-persist-root-merge/data/securefs.data.sig /overlay-persist-root-merge/data/securefs.data ;

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
		cat /overlay-persist-root-merge/data/securefs.data | chroot /overlay-persist-root-merge sha256sum -c -s ;

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

# Enforce root overlay, if requested
if [ $OVERLAYROOT_ENABLED -eq 1 ]; then

	CHECK=0 ;
	while [ $CHECK -eq 0 ];
	do 
		# Log
		do_log "Enabling overlay on root filesystem..." ;

		# Prepare folders for overlaying
		mkdir -p /overlay-ram-merge

		# Prepare overlay
		mkdir -p /overlay/ram 
		mkdir -p /overlay/ram/upper ;
		mkdir -p /overlay/ram/work ;

		# Mount overlay
		mount -t overlay -o lowerdir=/overlay-persist-root-merge,upperdir=/overlay/ram/upper,workdir=/overlay/ram/work overlay /overlay-ram-merge ;

		# Check the mount for being in place
		OVERLAY_VERIFICATION=`mount | grep "overlay on /overlay-ram-merge"` ;

		if [ -z "$OVERLAY_VERIFICATION" ]; then

			# Log
			do_log "Cannot enforce overlay on root filesystem!" ;
			do_panic ;

		else

			# Write a file on /initram for having a quick way for verifying at runtime if overlay is in place
			touch /initram/overlayroot.enforced ;

			CHECK=1 ;
		fi
	done

	# Make initram readonly
	mount -o remount,ro /initram

	# Move mounted file-system over overlay
	mount --move /overlay-persist-root-merge/boot /overlay-ram-merge/boot
	mount --move /overlay-persist-root-merge/var /overlay-ram-merge/var
	mount --move /overlay-persist-root-merge/data /overlay-ram-merge/data

	# Move temporary file systems to new root
	mkdir -p /overlay-ram-merge/initram
	mount --move /initram /overlay-ram-merge/initram

	# Move /overlay to /overlay-ram-merge (to make it visible when /overlay-ram-merge will become the new root)
	mkdir -p /overlay-ram-merge/overlay
	mount --move /overlay /overlay-ram-merge/overlay

	# Move /overlay-persist-root-merge to /overlay-ram-merge/overlay/persist-root-merge (to make is visible when /overlay-ram-merge will become the new root)
	mkdir -p /overlay-ram-merge/overlay/persisted-root
	mount --mount /overlay-persist-root-merge /overlay-ram-merge/overlay/persisted-root

else

	# Log
	do_log "Overlay on root filesystem DISABLED! Root filesystem is R/W!"

	# Make initram readonly
	mount -o remount,ro /initram

	# Move temporary file systems to new root
	mkdir -p /overlay-persist-root-merge/initram
	mount --move /initram /overlay-persist-root-merge/initram

	# Move /overlay to /overlay-persist-root-merge (to make it visible when /overlay-persist-root-merge will become the new root)
	mkdir -p /overlay-persist-root-merge/overlay
	mount --move /overlay /overlay-persist-root-merge/overlay
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
	exec switch_root /overlay-ram-merge /sbin/init ;
else
	exec switch_root /overlay-persist-root-merge /sbin/init ;
fi
