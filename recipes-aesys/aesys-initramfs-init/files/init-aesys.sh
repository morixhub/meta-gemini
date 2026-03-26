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

disable_wdog() {
    if [ -x "/usr/bin/hw-wdog-toggle.sh" ]; then
        do_log "Disabling watchdog..." ;
        /usr/bin/hw-wdog-toggle.sh disable ;
    fi
}

restore_wdog() {
    if [ -x "/usr/bin/hw-wdog-toggle.sh" ]; then
        do_log "Restoring watchdog..." ;
        /usr/bin/hw-wdog-toggle.sh default ;
    fi
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

# Declare file name
ROOTFSSQUASHFS=rootfs.squashfs

# Locate boot device
# (it is necessary because the boot device changes booting from uSD or eMMC)
KERNEL_CMDLINE=`cat /proc/cmdline`
OTHERBOOT_PART=
BOOT_PART=`echo ${KERNEL_CMDLINE} | sed -e 's/^.*root=//' -e 's/ .*$//'`
BOOT_DEVICE=`echo ${BOOT_PART} | sed 's/..$//'`
SECUREBOOT=`echo ${KERNEL_CMDLINE} | grep "secure-boot"`
DB_CMDLINE_CURRENTHALF=`echo ${KERNEL_CMDLINE} | grep "db_active_half="`
DB_CMDLINE_MODE=`echo ${KERNEL_CMDLINE} | grep "db_mode="`
DB_ROOTFSSQUASHFS="${ROOTFSSQUASHFS}"
DB_HALF=
DB_MODE=
if [ ! -z "${DB_CMDLINE_CURRENTHALF}" ] && [ ! -z "${DB_CMDLINE_MODE}" ]; then
	DB_HALF=`echo $DB_CMDLINE_CURRENTHALF | sed -e 's/^.*db_active_half=//' -e 's/ .*$//'` ;
	DB_MODE=`echo $DB_CMDLINE_MODE | sed -e 's/^.*db_mode=//' -e 's/ .*$//'` ;
	if [ "${DB_MODE}" == "partitions" ]; then
		if [ "${DB_HALF}" == "a" ]; then
			BOOT_PART=${BOOT_DEVICE}p1 ;
            OTHERBOOT_PART=${BOOT_DEVICE}p2 ;
			DATA_PART=${BOOT_DEVICE}p3 ;
		elif [ "${DB_HALF}" == "b" ]; then
			BOOT_PART=${BOOT_DEVICE}p2 ;
            OTHERBOOT_PART=${BOOT_DEVICE}p1 ;
			DATA_PART=${BOOT_DEVICE}p3 ;
		else
			BOOT_PART=${BOOT_DEVICE}p1 ;
			OTHERBOOT_PART=${BOOT_DEVICE}p2 ;
			DATA_PART=${BOOT_DEVICE}p3 ;
		fi
	else
		BOOT_PART=${BOOT_DEVICE}p1 ;
		DATA_PART=${BOOT_DEVICE}p2 ;

		DB_ROOTFSSQUASHFS="${ROOTFSSQUASHFS}.${DB_HALF}" ;
	fi
else
	BOOT_PART=${BOOT_DEVICE}p1 ;
	DATA_PART=${BOOT_DEVICE}p2 ;
fi

# Wait for block device
if [ ! -b ${BOOT_PART} ] || [ ! -b ${DATA_PART} ]; then
	do_log "Waiting for boot/data block device..." ;
	sleep 1 ;
fi

if [ ! -z ${OTHERBOOT_PART} ]; then
    do_log "Waiting for inactive boot block device..." ;
	sleep 1 ;
fi

# Heal and mount relevant file systems
e2fsck -p ${BOOT_PART} ;
mount -t ext4 -o ro ${BOOT_PART} /boot

e2fsck -p ${DATA_PART} ;
mount -t ext4 -o rw ${DATA_PART} /data

if [ ! -z ${OTHERBOOT_PART} ]; then
    mkdir -p /boot-inactive ;

    e2fsck -p ${OTHERBOOT_PART} ;
    mount -t ext4 -o ro ${OTHERBOOT_PART} /boot-inactive ;
fi

# Create /data/.sys folder, if not there
if [ ! -d /data/.sys ]; then
	mkdir -p /data/.sys
fi

# Determine if (early) shell is requested
EARLY_SHELL_REQUESTED=0
SHELL_REQUESTED=0
SHELL_CHROOT_DISABLED=0

if [ -e /data/.sys/earlyshell.requested ]; then
	EARLY_SHELL_REQUESTED=1 ;
fi

if [ -e /data/.sys/shell.requested ]; then
	SHELL_REQUESTED=1 ;
fi

if [ -e /data/.sys/shell-chroot.disabled ]; then
    SHELL_CHROOT_DISABLED=1 ;
fi

# Enter early shell, if requested
if [ $EARLY_SHELL_REQUESTED -eq 1 ]; then
	
	# Log
	do_log "Going to emergency (early) shell DUE TO REQUEST" ;

    # Disable WDOG
    disable_wdog ;

	# ash complains about no controlling terminal available, so wipe-out all ash messages
	# (lines starting with "ash:" dumped on stderr); the command line is tricky because
	# for piping stderr to grep we have to swap stdout and stderr
	ash 3>&2 2>&1 1>&3 3>&- | grep -v -e '^ash:' ;

    # Restore WDOG
    restore_wdog ;
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
            do_log "Data partition growth is requested..." ;

            # Disable WDOG
            disable_wdog ;

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

            # Restore WDOG
            restore_wdog ;
		fi
	fi
fi

# Create persist file in data, if not already there...
REPEAT=1
while [ $REPEAT -eq 1 ];
do
    if [ ! -f /data/.sys/persist.bin ]; then

        # Log
        do_log "Storage for persistent overlay has to be created..." ;

        # Disable WDOG
        disable_wdog ;

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

        # Restore WDOG
        restore_wdog ;
    fi

    PERSIST_BIN_ERROR=0 ;

    # Loop-load the file
    LOOP_DEVICE=`losetup -f` ;
    losetup -f /data/.sys/persist.bin ;
    RET=$? ;
    
    if [ $RET -ne 0 ] && [ $RET -ne 1 ]; then
        PERSIST_BIN_ERROR=1 ;
    else
        # Mount the persist file system
        mount -o rw $LOOP_DEVICE /persist ;
        RET=$? ;

        if [ $RET -ne 0 ]; then
            losetup -d $LOOP_DEVICE ;
            PERSIST_BIN_ERROR=1 ;
        fi
    fi

    # Check for errors
    if [ $PERSIST_BIN_ERROR -ne 0 ]; then
        if [ -e /data/.sys/persist.autofix ]; then
            # Remove existing (probably damaged) persistent storage...
            rm -rf /data/.sys/persist.bin ;
            # ... and let the loop repeat for generating a new one
        else
            # Error here: log and panic!
            do_log "An error occurred while mounting the persistent storage: cannot continue" ;
            do_panic ;
        fi
    else
        # Break the loop
        REPEAT=0 ;
    fi
done

# Mount initram filesystem
mount -t tmpfs -o mode=0755,nodev,nosuid,strictatime tmpfs /initram

# Clear temporary delta files (if there, they are a "remaining" of a failed delta update)
if [ -d "/data/.sys/.delta-tmp" ]; then
    rm -rf "/data/.sys/.delta-tmp" ;
    do_log "Removed stale delta temporary files" ; 
fi

# Clear temporary update files (if there, they are a "remaining" of a failed update)
if stat "/data/.sys/"*".update.tmp" 1>/dev/null 2>&1; then
    rm -fv "/data/.sys/"*".update.tmp" ;
    do_log "Removed stale update file(s)" ; 
fi

# Update rootfs (needs special treating since it is in boot partition)
ROOTFSUPDATES=("rootfs.squashfs" "rootfs.squashfs.a" "rootfs.squashfs.b") ;
for UPDATE in ${ROOTFSUPDATES[@]}; do
    if [ -f "/data/.sys/$UPDATE.update" ]; then
        
        # Log
        do_log "Updating rootfs ($UPDATE)..." ;

        # Disable WDOG
        disable_wdog ;

        # Remount boot as R/W
        mount -o remount,rw /boot ;

        # Copy new file
        TARGETDIGEST=$(sha256sum "/data/.sys/$UPDATE.update" 2>/dev/null | cut -d' ' -f1) ;
        cp -f "/data/.sys/$UPDATE.update" "/boot/$UPDATE" ;
        sync ;

        # Remount boot as R/O
        mount -o remount,ro /boot ;

        # Verification
        VERIFICATIONDIGEST=$(sha256sum "/boot/$UPDATE" 2>/dev/null | cut -d' ' -f1) ;

        if [ "$TARGETDIGEST" != "$VERIFICATIONDIGEST" ]; then
            # Error here: log and panic!
            do_log "Update of rootfs ($UPDATE) failed: verification problem" ;
            do_panic ;
        else
            # Remove update file
            rm -f "/data/.sys/$UPDATE.update" ;

            # Log
            do_log "Rootfs ($UPDATE) update completed successfully" ;
        fi

        # Restore WDOG
        restore_wdog ;
    fi
done

# Update extra
shopt -s nullglob
UPDATES=("/data/.sys/"*".update")
shopt -u nullglob
UPDATE=
for UPDATE in "${UPDATES[@]}"; do
    BN_UPDATE=$(basename -s ".update" "$UPDATE") ;
    if [ -f "/data/.sys/$BN_UPDATE.update" ]; then

        # Log
        do_log "Updating $BN_UPDATE..." ;

        # Disable WDOG
        disable_wdog ;

        # Copy new file
        TARGETDIGEST=$(sha256sum "/data/.sys/$BN_UPDATE.update" 2>/dev/null | cut -d' ' -f1) ;
        cp -f "/data/.sys/$BN_UPDATE.update" "/data/.sys/$BN_UPDATE" ;
        sync ;

        # Verification
        VERIFICATIONDIGEST=$(sha256sum "/data/.sys/$BN_UPDATE" 2>/dev/null | cut -d' ' -f1) ;

        if [ "$TARGETDIGEST" != "$VERIFICATIONDIGEST" ]; then
            # Error here: log and panic!
            do_log "Update of $BN_UPDATE failed" ;
            do_panic ;
        else
            # Remove update file
            rm -f "/data/.sys/$BN_UPDATE.update" ;

            # Log
            do_log "Update of $BN_UPDATE completed successfully" ;
        fi

        # Restore WDOG
        restore_wdog ;
    fi
done

# Log
do_log "Detecting extra filesystems..." ;

# Mount extra filesystems
EXTRA_ORIGINS=()
EXTRA_MOUNTS=()
shopt -s nullglob
EXTRAS=("/data/.sys/"*".squashfs"*)
shopt -u nullglob
EXTRA_BASENAMES=()
for EXTRA in "${EXTRAS[@]}"; do
    EXTRA_BN=$EXTRA
    EXTRA_BN=$(basename "$EXTRA_BN") ;
    EXTRA_BN=$(basename -s ".a" "$EXTRA_BN") ;
    EXTRA_BN=$(basename -s ".b" "$EXTRA_BN") ;
    EXTRA_BN=$(basename -s ".squashfs" "$EXTRA_BN") ;

    if [[ ! " ${EXTRA_BASENAMES[*]} " =~ [[:space:]]"$EXTRA_BN"[[:space:]] ]]; then
        # Collect filesystem base name
        EXTRA_BASENAMES+=("$EXTRA_BN") ;

        # Log
	    do_log "Detected extra filesystem ${EXTRA_BN}" ;
    fi
done

# Log
do_log "Mounting extra filesystems..." ;

EXTRA_BN=
for EXTRA_BN in ${EXTRA_BASENAMES[@]}; do
    if [ ! -z "$DB_HALF" ] && [ -f "/data/.sys/${EXTRA_BN}.squashfs.${DB_HALF}" ]; then

        # Collect extra origin/mount
        EXTRA_ORIGINS+=("${EXTRA_BN}.squashfs.${DB_HALF}") ;
        EXTRA_MOUNTS+=("${EXTRA_BN}") ;

        # Save info about origin
        echo "/data/.sys/${EXTRA_BN}.squashfs.${DB_HALF}" > "/initram/${EXTRA_BN}.mount" ;

        # Log
        do_log "Mounting filesystem ${EXTRA_BN}..." ;

        # Mount
        mkdir -p "/${EXTRA_BN}" ;
	    mount -t squashfs -o ro "/data/.sys/${EXTRA_BN}.squashfs.${DB_HALF}" "/${EXTRA_BN}" ;
    elif [ -f "/data/.sys/${EXTRA_BN}.squashfs" ]; then

        # Collect extra origin/mount
        EXTRA_ORIGINS+=("${EXTRA_BN}.squashfs") ;
        EXTRA_MOUNTS+=("${EXTRA_BN}") ;

        # Save info about origin
        echo "/data/.sys/${EXTRA_BN}.squashfs" > "/initram/${EXTRA_BN}.mount" ;

        # Log
        do_log "Mounting filesystem ${EXTRA_BN}..." ;

        # Mount
        mkdir -p "/${EXTRA_BN}" ;
	    mount -t squashfs -o ro "/data/.sys/${EXTRA_BN}.squashfs" "/${EXTRA_BN}" ;
    else
        # Log
	    do_log "Cannot mount filesystem ${EXTRA_BN}" ;
    fi
done

# Log
do_log "Mounting stock filesystems..." ;

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

# Move relevant mount points over persist overlay
mkdir -p /overlay-persist-root-merge/boot
mount --move /boot /overlay-persist-root-merge/boot

if [ ! -z "${OTHERBOOT_PART}" ]; then
    mkdir -p /overlay-persist-root-merge/boot-inactive ;
    mount --move /boot-inactive /overlay-persist-root-merge/boot-inactive ;
fi

mkdir -p /overlay-persist-root-merge/data
mount --move /data /overlay-persist-root-merge/data

for EXTRA_MOUNT in "${EXTRA_MOUNTS[@]}"; do
    mkdir -p "/overlay-persist-root-merge/${EXTRA_MOUNT}" ;
	mount --move "/${EXTRA_MOUNT}" "/overlay-persist-root-merge/${EXTRA_MOUNT}" ;
done

# Determine if overlayroot is requested
# Overlay can be explicitly disabled by file /data/.sys/overlayroot.disabled or
# silently implied by the first initialization procedure still pending
# (file /data/.sys/firstinit.pending still there)
OVERLAYROOT_ENABLED=1
if [ -e /overlay-persist-root-merge/data/.sys/overlayroot.disabled ] || [ -e /overlay-persist-root-merge/data/.sys/firstinit.pending ]; then
	OVERLAYROOT_ENABLED=0 ;
fi

# Make application-level signature key available to other applications
# (do it anyway, even if the SecureFS is going to be skipped by request afterward)
if [ -e /securefs.publickey.pem ]; then
	cp /securefs.publickey.pem /initram/securefs.publickey.pem ;
fi

# Make xdelta-apply.sh available
if [ -e /xdelta-apply.sh ]; then
    cp /xdelta-apply.sh /initram/xdelta-apply.sh ;
fi

# Make dual-tool-clone.sh and dual-tool-id.sh available, if requested
if [ ! -z "$DB_HALF" ]; then
    if [ -e /dual-tool-clone.sh ]; then
        cp /dual-tool-clone.sh /initram/dual-tool-clone.sh ;
    fi
    if [ -e /dual-tool-id.sh ]; then
        cp /dual-tool-id.sh /initram/dual-tool-id.sh ;
    fi
fi

# Check secure FS required files
# ATTENTION: only if in secure-boot mode (that is: the system booted from fit.img)
if [ ! -z "$SECUREBOOT" ] || [ -e /overlay-persist-root-merge/data/.sys/securefs.force ]; then

    # Log
    do_log "Checking for SecureFS..." ;

    # Check secure FS required files (rootfs)
    SKIPVERIFY=0
    CHECK=0
    while [ $CHECK -eq 0 ];
    do
        if [ -e /overlay-persist-root-merge/data/.sys/securefs.skip ] || [ -e /overlay-persist-root-merge/data/.sys/rootfs-securefs.skip ]; then
            SKIPVERIFY=1 ;
            CHECK=1 ;
        else
            if [ ! -e /initram/securefs.publickey.pem ] || [ ! -e /overlay/rootfs/securefs.data ] || [ ! -e /overlay/rootfs/securefs.data.sig ]; then
                do_log "SecureFS files not available! (rootfs)" ;
                do_panic ;
            else
                CHECK=1 ;    
            fi
        fi
    done

    if [ $SKIPVERIFY -eq 0 ]; then

        # Validate secure FS signature
        CHECK=0 ;
        while [ $CHECK -eq 0 ];
        do
            openssl dgst -sha256 -keyform PEM -verify /initram/securefs.publickey.pem -signature /overlay/rootfs/securefs.data.sig /overlay/rootfs/securefs.data ;

            if [ ! $? -eq 0 ]; then
                do_log "SecureFS signature verification FAILED! (rootfs)" ;
                do_panic ;
            else
                CHECK=1 ;
            fi
        done

        # Validate indexed files
        CHECK=0 ;
        while [ $CHECK -eq 0 ];
        do
            if [ -s /overlay/rootfs/securefs.data ]; then
                cat /overlay/rootfs/securefs.data | awk ' { print $1 " /overlay-persist-root-merge/"$2 } ' | sha256sum -c > /dev/null 2>&1 ;

                if [ ! $? -eq 0 ]; then
                    do_log "SecureFS files validation FAILED! (rootfs)" ;
                    do_panic ;
                else
                    CHECK=1 ;
                fi
            else
                CHECK=1 ;
            fi
        done

        # Log
        do_log "Filesystem (rootfs) verification SUCCEEDED: filesystem is secure" ;

    else

        # Log
        do_log "Filesystem (rootfs) verification was skipped DUE TO REQUEST" ;

    fi

    # Check secure FS required files (data)
    SKIPVERIFY=0
    CHECK=0
    while [ $CHECK -eq 0 ];
    do
        if [ -e /overlay-persist-root-merge/data/.sys/securefs.skip ] || [ -e /overlay-persist-root-merge/data/.sys/data-securefs.skip ]; then
            SKIPVERIFY=1 ;
            CHECK=1 ;
        else
            if [ ! -e /initram/securefs.publickey.pem ] || [ ! -e /overlay-persist-root-merge/data/.sys/securefs.data ] || [ ! -e /overlay-persist-root-merge/data/.sys/securefs.data.sig ]; then
                do_log "SecureFS files not available! (data)" ;
                do_panic ;
            else
                CHECK=1 ;
            fi
        fi
    done

    if [ $SKIPVERIFY -eq 0 ]; then

        # Validate secure FS signature
        CHECK=0 ;
        while [ $CHECK -eq 0 ];
        do
            openssl dgst -sha256 -keyform PEM -verify /initram/securefs.publickey.pem -signature /overlay-persist-root-merge/data/.sys/securefs.data.sig /overlay-persist-root-merge/data/.sys/securefs.data ;

            if [ ! $? -eq 0 ]; then
                do_log "SecureFS signature verification FAILED! (data)" ;
                do_panic ;
            else
                CHECK=1 ;
            fi
        done

        # Validate indexed files
        CHECK=0 ;
        while [ $CHECK -eq 0 ];
        do
            if [ -s /overlay-persist-root-merge/data/.sys/securefs.data ]; then
                cat /overlay-persist-root-merge/data/.sys/securefs.data | awk ' { print $1 " /overlay-persist-root-merge/data/"$2 } ' | sha256sum -c > /dev/null 2>&1 ;

                if [ ! $? -eq 0 ]; then
                    do_log "SecureFS files validation FAILED! (data)" ;
                    do_panic ;
                else
                    CHECK=1 ;
                fi
            else
                CHECK=1 ;
            fi
        done

        # Log
        do_log "Filesystem (data) verification SUCCEEDED: filesystem is secure" ;

    else

        # Log
        do_log "Filesystem (data) verification was skipped DUE TO REQUEST" ;

    fi

    # Check secure FS required files for extra filesystems, if requested
    EXTRA_MOUNT=
    for EXTRA_MOUNT in "${EXTRA_MOUNTS[@]}"; do

        SKIPVERIFY=0
        CHECK=0
        while [ $CHECK -eq 0 ];
        do
            if [ -e /overlay-persist-root-merge/data/.sys/securefs.skip ] || [ -e "/overlay-persist-root-merge/data/.sys/${EXTRA_MOUNT}-securefs.skip" ]; then
                SKIPVERIFY=1 ;
                CHECK=1 ;
            else
                if [ ! -e "/initram/securefs.publickey.pem" ] || [ ! -e "/overlay-persist-root-merge/${EXTRA_MOUNT}/securefs.data" ] || [ ! -e "/overlay-persist-root-merge/${EXTRA_MOUNT}/securefs.data.sig" ]; then
                    do_log "SecureFS files not available! (${EXTRA_MOUNT})" ;
                    do_panic ;
                else
                    CHECK=1 ;
                fi
            fi
        done

        if [ $SKIPVERIFY -eq 0 ]; then

            # Validate secure FS signature
            CHECK=0 ;
            while [ $CHECK -eq 0 ];
            do
                openssl dgst -sha256 -keyform PEM -verify "/initram/securefs.publickey.pem" -signature "/overlay-persist-root-merge/${EXTRA_MOUNT}/securefs.data.sig" "/overlay-persist-root-merge/${EXTRA_MOUNT}/securefs.data" ;

                if [ ! $? -eq 0 ]; then
                    do_log "SecureFS signature verification FAILED! (${EXTRA_MOUNT})" ;
                    do_panic ;
                else
                    CHECK=1 ;
                fi
            done

            # Validate indexed files
            CHECK=0 ;
            while [ $CHECK -eq 0 ];
            do
                if [ -s "/overlay-persist-root-merge/${EXTRA_MOUNT}/securefs.data" ]; then
                    cat "/overlay-persist-root-merge/${EXTRA_MOUNT}/securefs.data" | awk -v EM="${EXTRA_MOUNT}" ' { print $1 " /overlay-persist-root-merge/"EM"/"$2 } ' | sha256sum -c > /dev/null 2>&1 ;

                    if [ ! $? -eq 0 ]; then
                        do_log "SecureFS files validation FAILED! (${EXTRA_MOUNT})" ;
                        do_panic ;
                    else
                        CHECK=1 ;
                    fi
                else
                    CHECK=1 ;
                fi
            done

            # Log
            do_log "Filesystem verification SUCCEEDED for ${EXTRA_MOUNT}: filesystem is secure" ;

        else

            # Log
            do_log "Filesystem verification for ${EXTRA_MOUNT} was skipped DUE TO REQUEST" ;

        fi
    done
else

    # Log
    do_log "Filesystem verification was skipped because secure-boot was not enforced" ;

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
			# (the content of the file points to the root of the persisted root file system)
			echo "/overlay/persisted-root" > /initram/overlayroot.enforced ;
			chmod 444 /initram/overlayroot.enforced ;

			# Make overlayroot-commit.sh available
			if [ -e /overlayroot-commit.sh ]; then
				cp /overlayroot-commit.sh /initram/overlayroot-commit.sh ;
			fi

			CHECK=1 ;
		fi
	done

	# Make initram readonly
	mount -o remount,ro /initram

	# Move mounted file-system over overlay
	mount --move /overlay-persist-root-merge/var /overlay-ram-merge/var
	mount --move /overlay-persist-root-merge/boot /overlay-ram-merge/boot
	mount --move /overlay-persist-root-merge/data /overlay-ram-merge/data

    if [ ! -z "${OTHERBOOT_PART}" ]; then
        mount --move /overlay-persist-root-merge/boot-inactive /overlay-ram-merge/boot-inactive ;
    fi

    EXTRA_MOUNT=
    for EXTRA_MOUNT in "${EXTRA_MOUNTS[@]}"; do
        mount --move "/overlay-persist-root-merge/${EXTRA_MOUNT}" "/overlay-ram-merge/${EXTRA_MOUNT}" ;
    done

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

        # Disable WDOG
        disable_wdog ;

		# ash complains about no controlling terminal available, so wipe-out all ash messages
		# (lines starting with "ash:" dumped on stderr); the command line is tricky because
		# for piping stderr to grep we have to swap stdout and stderr; further we have to
		# invoke an intermediate shell for doing that, because otherwise redirection will
		# occur for chroot, and not for ash
        if [ $SHELL_CHROOT_DISABLED -eq 1 ]; then
            ash 3>&2 2>&1 1>&3 3>&- | grep -v -e '^ash:' ;
        else
    		chroot /overlay-ram-merge sh -c "ash 3>&2 2>&1 1>&3 3>&- | grep -v -e '^ash:'" ;
        fi

        # Restore WDOG
        restore_wdog ;
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

        # Disable WDOG
        disable_wdog ;

		# ash complains about no controlling terminal available, so wipe-out all ash messages
		# (lines starting with "ash:" dumped on stderr); the command line is tricky because
		# for piping stderr to grep we have to swap stdout and stderr; further we have to
		# invoke an intermediate shell for doing that, because otherwise redirection will
		# occur for chroot, and not for ash
		chroot /overlay-persist-root-merge sh -c "ash 3>&2 2>&1 1>&3 3>&- | grep -v -e '^ash:'" ;

        # Restore WDOG
        restore_wdog ;
	fi
fi

# Handover
do_log "Switching root..."

if [ $OVERLAYROOT_ENABLED -eq 1 ]; then
	exec switch_root /overlay-ram-merge /sbin/init ;
else
	exec switch_root /overlay-persist-root-merge /sbin/init ;
fi
