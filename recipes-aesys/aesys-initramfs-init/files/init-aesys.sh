#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin

do_log() {
	printf "INITRAM: %s\n" "$1" > /dev/kmsg ;
}

do_panic() {
	do_log "PANIC during INITRAM phase: ENTERING CONSOLE FOR DEBUGGING" ;

	# ash complains about no controlling terminal available, so wipe-out all ash messages
	# (lines starting with "ash:" dumped on stderr); the command line is tricky because
	# for piping stderr to grep we have to swap stdout and stderr
	ash 3>&2 2>&1 1>&3 3>&- | grep -v -e '^ash:' ;
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
mkdir -p /app
mkdir -p /data

# Mount aux filesystems
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs dev /dev

# Declare file name
ROOTFSSQUASHFS=rootfs.squashfs
APPBIN=app.bin

# Locate boot device
# (it is necessary because the boot device changes booting from uSD or eMMC)
KERNEL_CMDLINE=`cat /proc/cmdline`
BOOT_PART=`echo ${KERNEL_CMDLINE} | sed -e 's/^.*root=//' -e 's/ .*$//'`
BOOT_DEVICE=`echo ${BOOT_PART} | sed 's/..$//'`
DB_CMDLINE_CURRENTHALF=`echo ${KERNEL_CMDLINE} | grep "db_current_half="`
DB_CMDLINE_MODE=`echo ${KERNEL_CMDLINE} | grep "db_mode="`
DB_ROOTFSSQUASHFS="${ROOTFSSQUASHFS}"
DB_APPBIN="${APPBIN}"
if [ ! -z "${DB_CMDLINE_CURRENTHALF}" ] && [ ! -z "${DB_CMDLINE_MODE}" ]; then
	DB_HALF=`echo $DB_CMDLINE_CURRENTHALF | sed -e 's/^.*db_current_half=//' -e 's/ .*$//'` ;
	DB_MODE=`echo $DB_CMDLINE_MODE | sed -e 's/^.*db_mode=//' -e 's/ .*$//'` ;
	if [ "${DB_MODE}" == "partitions" ]; then
		if [ "${DB_HALF}" == "a" ]; then
			BOOT_PART=${BOOT_DEVICE}p1 ;
			DATA_PART=${BOOT_DEVICE}p3 ;
		elif [ "${DB_HALF}" == "b" ]; then
			BOOT_PART=${BOOT_DEVICE}p2 ;
			DATA_PART=${BOOT_DEVICE}p3 ;
		else
			BOOT_PART=${BOOT_DEVICE}p1 ;
			DATA_PART=${BOOT_DEVICE}p2 ;
		fi
	else
		BOOT_PART=${BOOT_DEVICE}p1 ;
		DATA_PART=${BOOT_DEVICE}p2 ;

		DB_ROOTFSSQUASHFS="${ROOTFSSQUASHFS}.${DB_HALF}" ;
	fi
	DB_APPBIN="${APPBIN}.${DB_HALF}" ;
else
	BOOT_PART=${BOOT_DEVICE}p1 ;
	DATA_PART=${BOOT_DEVICE}p2 ;
fi

# Wait for block device
if [ ! -b ${BOOT_PART} ] || [ ! -b ${DATA_PART} ]; then
	do_log "Waiting for block device..." ;
	sleep 1 ;
fi

# Mount relevant file systems
mount -t ext4 -o ro ${BOOT_PART} /boot
mount -t ext4 -o rw ${DATA_PART} /data

# Create /data/.sys folder, if not there
if [ ! -d /data/.sys ]; then
	mkdir -p /data/.sys
fi

# Determine if (early) shell is requested
EARLY_SHELL_REQUESTED=0
SHELL_REQUESTED=0

if [ -e /data/.sys/earlyshell.requested ]; then
	EARLY_SHELL_REQUESTED=1 ;
fi

if [ -e /data/.sys/shell.requested ]; then
	SHELL_REQUESTED=1 ;
fi

# Enter early shell, if requested
if [ $EARLY_SHELL_REQUESTED -eq 1 ]; then
	
	# Log
	do_log "Going to emergency (early) shell DUE TO REQUEST" ;

	# ash complains about no controlling terminal available, so wipe-out all ash messages
	# (lines starting with "ash:" dumped on stderr); the command line is tricky because
	# for piping stderr to grep we have to swap stdout and stderr
	ash 3>&2 2>&1 1>&3 3>&- | grep -v -e '^ash:' ;
fi

# Enlarge data partition, if requested
FIRSTINIT=0
PARTNUMBER=`mount | grep -e "^$BOOT_DEVICE" | grep /data | awk '{ print $1 }' | awk '{ print substr($0,length($0),1) }'`
BOOT_DEVICE_DEVNAME=${BOOT_DEVICE#"/dev/"} ;
DATA_SIZE=`lsblk -b | grep -i -e "${BOOT_DEVICE_DEVNAME}p${PARTNUMBER}" | awk ' { print $4 } '` ;

if [ ! -f /data/.sys/datagrow.disabled ]; then

	if [ ! -z "$PARTNUMBER" ]; then

		# Determine if there is unpartitioned space at the end of the disk
		EMPTY_SPACE=`parted ${BOOT_DEVICE} print free | grep "\S" | tail -1 | grep -i "free"` ;

		if [ ! -z "$EMPTY_SPACE" ]; then

			# Log
			do_log "Resizing data partition..." ;
			
			# Resize data partition
			printf 'yes\n100%%' | parted ${BOOT_DEVICE} resizepart $PARTNUMBER ---pretend-input-tty ;

			# Log
			do_log "Resizing data filesystem..." ;

			# Resize file system
			resize2fs ${BOOT_DEVICE}p${PARTNUMBER} ;

			# Recalculate the size of /data
			DATA_SIZE=`lsblk -b | grep -i -e "${BOOT_DEVICE_DEVNAME}p${PARTNUMBER}" | awk ' { print $4 } '` ;
		fi
	fi
fi

# Create persist file in data, if not already there...
if [ ! -f /data/.sys/persist.bin ]; then

	# Log
	do_log "Flagging the system for firstinit..." ;

	# If the persistence layer was not there, then we have to force again a first-initialization
	touch /data/.sys/firstinit.pending ;

	# Log
	do_log "Creating storage file for persistence overlay..." ;

	# Determine max size (as the half of the available space on /data)
	MAX_SIZE=$(( DATA_SIZE / 2 )) ;
	
	# Create file
	dd if=/dev/null of=/data/.sys/persist.bin bs=1 seek=$MAX_SIZE ;

	# Log
	do_log "Formatting storage file for persistence overlay..." ;

	# Loop-load the file
	LOOP_DEVICE=`losetup -f` ;
	losetup -f /data/.sys/persist.bin ;

	# Create ext4 filesystem
	mkfs.ext4 $LOOP_DEVICE ;

	# Release the loop
	losetup -d $LOOP_DEVICE ;
fi

# Mount the persist file system
mount -o loop,rw /data/.sys/persist.bin /persist

# Mount the app file system
APP_MOUNTED=0
if [ -f /data/.sys/${DB_APPBIN} ]; then
	APP_MOUNTED=1 ;

	# Log
	do_log "Mounting (dual-boot) app filesystem..." ;

	# Mount
	mount -o loop,ro /data/.sys/${DB_APPBIN} /app ;
elif [ -f /data/.sys/${APPBIN} ]; then
	APP_MOUNTED=1 ;

	# Log
	do_log "Mounting app filesystem..." ;

	# Mount
	mount -o loop,ro /data/.sys/${APPBIN} /app ;
else
	# Log
	do_log "app filesystem not found" ;
fi

# Log
do_log "Mounting filesystems..." ;

# Mount initram filesystems
mount -t tmpfs -o mode=0755,nodev,nosuid,strictatime tmpfs /initram

# Set U-Boot environment to /initram
echo "${BOOT_DEVICE} 0x700000 0x4000" > /initram/fw_env.config

# Ensure persist filesystem has folders requested for overlay
mkdir -p /persist/upper
mkdir -p /persist/work

# Mount root file system from squash
mount -t squashfs -o ro /boot/${DB_ROOTFSSQUASHFS} /rootfs

# Create a temporary mount on /overlay
# (so that it can act as a real mount point and can be moved around)
mkdir -p /overlay
mount -t tmpfs tmpfs /overlay

# Prepare folders for overlaying
mkdir -p /overlay/rootfs
mkdir -p /overlay/persist
mkdir -p /overlay-ram-var-merge
mkdir -p /overlay-persist-root-merge

# Move rootfs mount point to overlay lower
mount --move /rootfs /overlay/rootfs
mount --move /persist /overlay/persist

# Log
do_log "Mounting RAM overlay for /var..." ;

# Mount RAM overlay for /var
mkdir -p /overlay/ram ;
mkdir -p /overlay/ram/var ;
mkdir -p /overlay/ram/var/upper ;
mkdir -p /overlay/ram/var/work ;
mount -t overlay -o lowerdir=/overlay/rootfs/var,upperdir=/overlay/ram/var/upper,workdir=/overlay/ram/var/work overlay /overlay-ram-var-merge ;

# Log
do_log "Mounting persistence overlay for root filesystem..." ;

# Mount overlay on persist (root)
mount -t overlay -o lowerdir=/overlay/rootfs,upperdir=/overlay/persist/upper,workdir=/overlay/persist/work overlay /overlay-persist-root-merge ;

# Move persisted var overlay to persist overlay
mkdir -p /overlay-persist-root-merge/var
mount --move /overlay-ram-var-merge /overlay-persist-root-merge/var

# Move boot, app and data mount points over persist overlay
mkdir -p /overlay-root-merge/boot
mount --move /boot /overlay-persist-root-merge/boot

mkdir -p /overlay-persist-root-merge/data
mount --move /data /overlay-persist-root-merge/data

if [ $APP_MOUNTED -eq 1 ]; then
	mkdir -p /overlay-persist-root-merge/app ;
	mount --move /app /overlay-persist-root-merge/app ;
fi

# Determine if overlayroot is requested
# Overlay can be explicitly disabled by file /data/.sys/overlayroot.disabled or
# silently implied by the first initialization procedure still pending
# (file /data/.sys/firstinit.pending still there)
OVERLAYROOT_ENABLED=1
if [ -e /overlay-persist-root-merge/data/.sys/overlayroot.disabled ] || [ -e /overlay-persist-root-merge/data/.sys/firstinit.pending ]; then
	OVERLAYROOT_ENABLED=0 ;
fi

# Make APP signature key available to other applications
# (do it anyway, even if the SecureFS is going to be skipped by request afterward)
if [ -e /securefs.publickey.pem ]; then
	cp /securefs.publickey.pem /initram/securefs.publickey.pem ;
fi

# Log
do_log "Checking for SecureFS..." ;

# Check secure FS required files
SKIPVERIFY=0
CHECK=0
while [ $CHECK -eq 0 ];
do
	if [ ! -e /initram/securefs.publickey.pem ] || [ ! -e /overlay-persist-root-merge/data/.sys/securefs.data ] || [ ! -e /overlay-persist-root-merge/data/.sys/securefs.data.sig ]; then
		if [ -e /overlay-persist-root-merge/data/.sys/securefs.skip ]; then
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
		openssl dgst -sha256 -keyform PEM -verify /initram/securefs.publickey.pem -signature /overlay-persist-root-merge/data/.sys/securefs.data.sig /overlay-persist-root-merge/data/.sys/securefs.data ;

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
		cat /overlay-persist-root-merge/data/.sys/securefs.data | chroot /overlay-persist-root-merge sha256sum -c > /dev/null 2>&1 ;

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
	do_log "Filesystem verification was skipped DUE TO REQUEST" ;

fi

# Log
do_log "Preparing for root switching..."

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
		mkdir -p /overlay/ram/root ; 
		mkdir -p /overlay/ram/root/upper ;
		mkdir -p /overlay/ram/root/work ;

		# Mount overlay
		mount -t overlay -o lowerdir=/overlay-persist-root-merge,upperdir=/overlay/ram/root/upper,workdir=/overlay/ram/root/work overlay /overlay-ram-merge ;

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
	mount --move /overlay-persist-root-merge/var /overlay-ram-merge/var
	mount --move /overlay-persist-root-merge/boot /overlay-ram-merge/boot
	mount --move /overlay-persist-root-merge/data /overlay-ram-merge/data

	if [ $APP_MOUNTED -eq 1 ]; then
		mount --move /overlay-persist-root-merge/app /overlay-ram-merge/app
	fi

	# Move system mounts to new root
	mount --move /proc /overlay-ram-merge/proc
	mount --move /sys /overlay-ram-merge/sys
	mount --move /dev /overlay-ram-merge/dev

	# Move temporary file systems to new root
	mkdir -p /overlay-ram-merge/initram
	mount --move /initram /overlay-ram-merge/initram

	# Move /overlay to /overlay-ram-merge (to make it visible when /overlay-ram-merge will become the new root)
	mkdir -p /overlay-ram-merge/overlay
	mount --move /overlay /overlay-ram-merge/overlay

	# Move /overlay-persist-root-merge to /overlay-ram-merge/overlay/persist-root-merge (to make is visible when /overlay-ram-merge will become the new root)
	mkdir -p /overlay-ram-merge/overlay/persisted-root
	mount --mount /overlay-persist-root-merge /overlay-ram-merge/overlay/persisted-root

	# Go to chrooted shell, if requested
	if [ $SHELL_REQUESTED -eq 1 ]; then
		
		# Log
		do_log "Going to emergency shell due to request... Type ENTER to get the prompt" ;

		# ash complains about no controlling terminal available, so wipe-out all ash messages
		# (lines starting with "ash:" dumped on stderr); the command line is tricky because
		# for piping stderr to grep we have to swap stdout and stderr; further we have to
		# invoke an intermediate shell for doing that, because otherwise redirection will
		# occur for chroot, and not for ash
		chroot /overlay-ram-merge sh -c "ash 3>&2 2>&1 1>&3 3>&- | grep -v -e '^ash:'" ;
	fi

else

	# Log
	do_log "Overlay on root filesystem DISABLED! Root filesystem is R/W!"

	# Make initram readonly
	mount -o remount,ro /initram

	# Move system mounts to new root
	mount --move /proc /overlay-persist-root-merge/proc
	mount --move /sys /overlay-persist-root-merge/sys
	mount --move /dev /overlay-persist-root-merge/dev

	# Move temporary file systems to new root
	mkdir -p /overlay-persist-root-merge/initram
	mount --move /initram /overlay-persist-root-merge/initram

	# Move /overlay to /overlay-persist-root-merge (to make it visible when /overlay-persist-root-merge will become the new root)
	mkdir -p /overlay-persist-root-merge/overlay
	mount --move /overlay /overlay-persist-root-merge/overlay

	# Go to chrooted shell, if requested
	if [ $SHELL_REQUESTED -eq 1 ]; then
		
		# Log
		do_log "Going to emergency shell due to request... Type ENTER to get the prompt" ;

		# ash complains about no controlling terminal available, so wipe-out all ash messages
		# (lines starting with "ash:" dumped on stderr); the command line is tricky because
		# for piping stderr to grep we have to swap stdout and stderr; further we have to
		# invoke an intermediate shell for doing that, because otherwise redirection will
		# occur for chroot, and not for ash
		chroot /overlay-persist-root-merge sh -c "ash 3>&2 2>&1 1>&3 3>&- | grep -v -e '^ash:'" ;
	fi
fi

# Handover
do_log "Switching root..."

if [ $OVERLAYROOT_ENABLED -eq 1 ]; then
	exec switch_root /overlay-ram-merge /sbin/init ;
else
	exec switch_root /overlay-persist-root-merge /sbin/init ;
fi
