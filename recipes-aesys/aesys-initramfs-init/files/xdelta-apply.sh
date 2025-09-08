#!/bin/bash

# Functions declaration
log () {
    echo "$1" ;
}

log_warning () {
    echo "WARNING: $1" >&2 ;
}

log_error () {
    echo >&2 ;
    echo "ERROR: $1" >&2 ;
    echo >&2 ;
}

clean_up () {

    # Remove package index, if any
    if [ -f "$PACKAGEINDEX" ]; then
        rm -rf "$PACKAGEINDEX" ;
    fi

    # Remove package index signature, if any
    if [ -f "$PACKAGEINDEXSIG" ]; then
        rm -rf "$PACKAGEINDEXSIG" ;
    fi

    # Remove pre.sh, if any
    if [ -f "$PACKAGEPRE" ]; then
        rm -rf "$PACKAGEPRE" ;
    fi

    # Remove post.sh, if any
    if [ -f "$PACKAGEPOST" ]; then
        rm -rf "$PACKAGEPOST" ;
    fi

    # Remove support files for boot loader update, if any
    if [ -f "$UBOOTBIN" ]; then
        rm -rf "$UBOOTBIN" ;
    fi
    if [ -f "$UBOOTBINEX" ]; then
        rm -rf "$UBOOTBINEX" ;
    fi

    if [ $SIMULATION -ne 1 ]; then
        if [ "$PLATFORM" == "gemini" ]; then
            # Ensure boot folder is remounted RO on Gemini
            if [ ! -z "$BOOTFOLDER" ] && [ -d "$BOOTFOLDER" ]; then
                mount -o remount,ro "${BOOTFOLDER}" >/dev/null 2>/dev/null ;
            fi

            # Ensure inactive boot folder is remounted RO on Gemini
            if [ ! -z "$BOOTFOLDEROTHER" ] && [ -d "$BOOTFOLDEROTHER" ]; then
                mount -o remount,ro "${BOOTFOLDEROTHER}" >/dev/null 2>/dev/null ;
            fi
        fi

        # Restore initial kernel printk levels
        if [ ! -z "$INITIAL_PRINT_LEVELS" ]; then
            sysctl -w kernel.printk="$INITIAL_PRINT_LEVELS" >/dev/null 2>/dev/null;
        fi
    fi

    # Remove temp files, if any
    if [ "$PLATFORM" == "gemini" ]; then
        if [ -d "$DATAFOLDER/.delta-tmp" ]; then
            rm -rf "$DATAFOLDER/.delta-tmp" ;
        fi
    fi
}

get_temp_for_size () {

    # If not on GEMINI platform then temporary location is always the system one
    if [ "$PLATFORM" != "gemini" ]; then
        TEMPLOCATION=$(mktemp) ;
        return 0;
    fi

    # Reset location
    USE_RAM=0 ;

    # Get the size we are requesting for from input
    TEMPSIZE=$(( "$1" )) ;

    if [ $TEMPSIZE -gt 0 ]; then

        # Determine maximum available RAM
        AVAILABLERAM=0 ;
        if [ $FORCEDMAXRAM -gt 0 ]; then
            AVAILABLERAM=$FORCEDMAXRAM ;
        else
            # Determine the maximum size available on /tmp (1K-blocks)
            TOTALAVAILABLETMP=$(( $(df "/tmp" | grep -i "tmpfs" | awk ' { print $4 } ') ));
            if [ $? -eq 0 ] && [ $TOTALAVAILABLETMP -gt 0 ]; then
                # The maximum available RAM for storage is half the total available
                AVAILABLERAM=$(( $TOTALAVAILABLETMP * 1024 / 2 )) ;
            fi
        fi

        # If requested size is available in RAM, then use RAM
        if [ $TEMPSIZE -le $AVAILABLERAM ]; then
            USE_RAM=1 ;
        fi

        # If RAM has to be used, then we can proceed...
        if [ $USE_RAM -eq 1 ]; then
            log "+ Using RAM storage ($TEMPSIZE out of $AVAILABLERAM bytes available)" ;
            TEMPLOCATION=$(mktemp);
            return 0;
        fi

        # ...otherwise we can check if there is enough space on disk
        AVAILABLEDISK=0 ;
        TOTALAVAILABLEDISK=$(( $(df "/data/.sys" | grep -i "/data" | awk ' { print $4 } ') ));
        if [ $? -eq 0 ] && [ $TOTALAVAILABLEDISK -gt 0 ]; then
            AVAILABLEDISK=$(( $TOTALAVAILABLEDISK * 1024 )) ;
        fi

        if [ $TEMPSIZE -le $AVAILABLEDISK ]; then
            log "+ Using disk storage ($TEMPSIZE out of $AVAILABLEDISK bytes available)" ;
            mkdir -p "/data/.sys/.delta-tmp" ;
            TEMPLOCATION=$(mktemp -p "/data/.sys/.delta-tmp") ;
            return 0;
        fi
    else
        log "+ Using disk storage (unknown size requested)" ;
        mkdir -p "/data/.sys/.delta-tmp" ;
        TEMPLOCATION=$(mktemp -p "/data/.sys/.delta-tmp") ;
        return 0;
    fi

    return -1;
}

get_asset () {
    URL="$1" ;

    if [[ "$URL" == http://* ]] || [[ "$URL" == https://* ]]; then
        wget -O - "$URL" 2>/dev/null ;
    elif [[ "$URL" == scp://* ]] || [[ "$URL" == ssh://* ]]; then
        # Environment variable SSHPASS should contain the password, if requested
        # (other options may be passed via SCPOPTIONS variable)
        if [ ! -z "$SSHPASS" ]; then
            sshpass -e scp $SCPOPTIONS -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -O "${URL#*://}" /dev/stdout 2>/dev/null ;
        else
            scp $SCPOPTIONS -B -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -O "${URL#*://}" /dev/stdout 2>/dev/null ;
        fi
    elif [[ "$URL" == sftp://* ]]; then
        # Environment variable SFTPOPTIONS should contain the extra parameter for curl, if requested
        # (especially the `--user` parameter for authenticated access to the server)
        curl $SFTPOPTIONS -k "$URL" --output /dev/stdout 2>/dev/null ;
    else
        cat ${URL#*file://} 2>/dev/null ;
    fi
}

delta_file () {
    # Process file name
    FOLDER="${1}" ;
    FILE="${2}" ;
    OTHERFOLDER="${3}" ;

    # Log
    log "Checking file ${FILE}..."

    # Determine if, depending on boot scheme, the file has to be processed
    BASEFILE= ;
    TARGETFILE= ;
    WRITEFILE= ;
    if [ "$FILE" == "uboot.bin" ]; then
        BASEFILE="$FILE" ;
        TARGETFILE=$(basename "$UBOOTBIN") ;
        WRITEFILE="$TARGETFILE" ;
        OTHERFOLDER=$(dirname "$UBOOTBIN") ;
    else
        if [ -z "${DB_HALF}" ]; then
            if [[ $FILE == *.a ]] || [[ $FILE == *.b ]]; then
                log "+ Skipped: half-based file while in single boot scheme" ;
            else
                BASEFILE="$FILE" ;

                # Special treatment for non-boot assets, if in single boot partition mode
                # (in this case they are updated by system start-up script
                # since they might be in use, and so not directly updatable)
                if [ "$FILE" == "rootfs.squashfs" ] || [ "$FILE" == "app.squashfs" ]; then
                    TARGETFILE="$FILE" ;
                    WRITEFILE="$FILE.update.tmp" ;
                    OTHERFOLDER="$DATAFOLDER" ;
                else
                    TARGETFILE="$FILE" ;
                    WRITEFILE="$TARGETFILE" ;
                fi
            fi
        elif [ "${DB_MODE}" == "partitions" ]; then
            if [[ $FILE == *.a ]] || [[ $FILE == *.b ]]; then
                # In dual boot (partitions-based) mode the app.squashfs is the
                # only file that is managed anyway via .a and .b, and this
                # fact has to be managed
                if [[ $FILE == app.squashfs.* ]]; then
                    if [[ $FILE != *.${DB_HALF} ]]; then
                        log "+ Skipped: not current-half file while in dual (partitions-based) boot scheme" ;
                    else
                        BASEFILE="${FILE::-2}" ;
                        if [ ! -z "$DB_FORCED_SINGLE" ]; then
                            TARGETFILE="$FILE" ;
                            WRITEFILE="$FILE.update.tmp" ;
                            OTHERFOLDER="$DATAFOLDER" ;
                        else
                            if [ "${DB_HALF}" == "a" ]; then
                                TARGETFILE="$BASEFILE.b" ;
                                WRITEFILE="$TARGETFILE" ;
                            else
                                TARGETFILE="$BASEFILE.a" ;
                                WRITEFILE="$TARGETFILE" ;
                            fi
                        fi
                    fi
                else
                    log "+ Skipped: half-based file while in dual (partitions-based) boot scheme" ;
                fi
            else
                BASEFILE="$FILE" ;

                # Special treatment for app.squashfs while in dual-boot (partitions-based),
                # for handing the case when /app was mount from failsafe app.squashfs
                # and not from the app.squashfs.<current_half>
                # (in this case the file is updated by system start-up script
                # since it might be in use, and so not directly updatable)
                if [ "$FILE" == "app.squashfs" ]; then
                    TARGETFILE="$FILE" ;
                    WRITEFILE="$FILE.update.tmp" ;
                    OTHERFOLDER="$DATAFOLDER" ;
                else
                    TARGETFILE="$FILE" ;
                    WRITEFILE="$TARGETFILE" ;
                fi
            fi
        else
            if [[ $FILE != *.${DB_HALF} ]]; then
                # Special treatment for app.squashfs while in dual-boot (files-based),
                # for handing the case when /app was mount from failsafe app.squashfs
                # and not from the app.squashfs.<current_half>
                # (in this case the file is updated by system start-up script
                # since it might be in use, and so not directly updatable)
                if [[ $FILE == "app.squashfs" ]]; then
                    BASEFILE="$FILE" ;
                    TARGETFILE="$FILE" ;
                    WRITEFILE="$FILE.update.tmp" ;
                    OTHERFOLDER="$DATAFOLDER" ;
                else
                    log "+ Skipped: not current-half file while in dual (files-based) boot scheme" ;
                fi
            else
                BASEFILE="${FILE::-2}" ;
                if [ ! -z "$DB_FORCED_SINGLE" ]; then
                    if [[ "$FILE" == rootfs.squashfs.* ]] || [[ "$FILE" == app.squashfs.* ]]; then
                        TARGETFILE="$FILE" ;
                        WRITEFILE="$FILE.update.tmp" ;
                        OTHERFOLDER="$DATAFOLDER" ;
                    else
                        TARGETFILE="$BASEFILE.${DB_HALF}" ;
                        WRITEFILE="$TARGETFILE" ;
                    fi
                else
                    if [ "${DB_HALF}" == "a" ]; then
                        TARGETFILE="$BASEFILE.b" ;
                        WRITEFILE="$TARGETFILE" ;
                    else
                        TARGETFILE="$BASEFILE.a" ;
                        WRITEFILE="$TARGETFILE" ;
                    fi
                fi
            fi
        fi
    fi

    if [ ! -z "$WRITEFILE" ] && [ ! -z "$TARGETFILE" ] && [ ! -z "$BASEFILE" ]; then

        # Determine the folder for outputting the result
        if [ -z "$OUTPUTFOLDER" ]; then
            if [ ! -z "${OTHERFOLDER}" ]; then
                WORKOUTPUT="$OTHERFOLDER" ;
            else
                WORKOUTPUT="$FOLDER" ;
            fi
        else
            WORKOUTPUT="$OUTPUTFOLDER" ;
        fi

        # Declare vars
        COPYFROMEXISTING=0 ;

        # Check if the file is in the index as a target file
        TARGETENTRY=$(cat "$PACKAGEINDEX" | grep "${BASEFILE}=") ;

        if [ ! -z "$TARGETENTRY" ]; then

            # Extract target details
            TARGETENTRYVALUE=$(echo "$TARGETENTRY" | cut -d'=' -f2) ;
            TARGETDIGEST=$(echo "$TARGETENTRYVALUE" | cut -d',' -f1) ;
            TARGETSIZE=$(( $(echo "$TARGETENTRYVALUE" | cut -d',' -f2) )) ;

            if [ -z "$TARGETDIGEST" ] || [ $TARGETSIZE -le 0 ]; then
                log_error "Cannot determine target digest and/or size: cannot continue" ;
                return -1 ;
            fi

            # Calculate existing file digest
            if [ "$BASEFILE" == "uboot.bin" ]; then
                EXFILE="$UBOOTBINEX" ;
                dd if="${FOLDER}" of="$EXFILE" bs=1024 skip=32 iflag=count_bytes count=$TARGETSIZE >/dev/null 2>/dev/null ;
            else
                EXFILE=${FOLDER}/${FILE} ;
            fi

            EXDIGEST=$(sha256sum "${EXFILE}" 2>/dev/null | cut -d' ' -f1) ;

            if [ "$TARGETDIGEST" != "$EXDIGEST" ]; then

                # Log
                log "+ File needs update" ;

                if [ -f "${FOLDER}/${TARGETFILE}" ]; then
                    VERIFICATIONDIGEST=$(sha256sum "${FOLDER}/${TARGETFILE}" 2>/dev/null | cut -d' ' -f1) ;
                    if [ "$TARGETDIGEST" == "$VERIFICATIONDIGEST" ]; then
                        log "+ Target file is already good: no need for further processing" ;

                        # Flag the system for changes
                        if [ "$FILE" != "uboot.bin" ]; then
                            REBOOTPENDING=1 ;
                        fi

                        return 0 ;
                    fi
                fi

                # Set the flag for using resource
                # (the flag is going to be reset only if delta is retrieved and applied successfully)
                USE_RESOURCE=1;

                # Check if the file exists as a delta in the package
                DELTAENTRY=$(cat "$PACKAGEINDEX" | grep "${EXDIGEST}=") ;

                if [ ! -z "$DELTAENTRY" ]; then

                    # Extract delta details
                    DELTAENTRYVALUE=$(echo "$DELTAENTRY" | cut -d'=' -f2) ;
                    DELTASOURCE=$(echo "$DELTAENTRYVALUE" | cut -d',' -f1) ;
                    DELTASIZE=$(( $(echo "$DELTAENTRYVALUE" | cut -d',' -f2) )) ;

                    if [ $DOWNLOADPATCHES -eq 0 ]; then
                        if [ $SIMULATION -eq 1 ]; then
                            log "+ Applying delta... (ACTUALLY PREVENTED BY SIMULATION MODE)" ;

                            # If here we can assume that delta can be successfully applied and verified
                            USE_RESOURCE=0 ;
                        else
                            # Flag the system for changes
                            if [ "$FILE" != "uboot.bin" ]; then
                                REBOOTPENDING=1 ;
                            fi

                            # Clear target half ID when the first file is being touched
                            if [ "$PLATFORM" == "gemini" ]; then
                                if [ $CLEAREDID -eq 0 ]; then
                                    CLEAREDID=1 ;
                                    if [ -x "/initram/dual-tool-id.sh" ]; then
                                        /initram/dual-tool-id.sh -b -t ${TARGETHALF} -c ;

                                        if [ $? -ne 0 ]; then
                                            log "# Cannot clear target half ID (error during operation)" ;
                                            return -1;
                                        fi
                                    else
                                        log "# Cannot clear target half ID (no script available)" ;
                                    fi
                                fi
                            fi

                            # Apply delta
                            log "+ Applying delta..." ;
                            get_asset "${PACKAGEFOLDER}/delta/${BASEFILE}/${EXDIGEST}.delta" | xdelta3 -c -d -f -D -R -S djw -s "${EXFILE}" > "${WORKOUTPUT}/${WRITEFILE}" 2>/dev/null ;

                            if [ $? -ne 0 ]; then
                                log_error "Error while applying patch: cannot continue" ;
                                return -2 ;
                            fi

                            # Flush
                            sync ;

                            # Perform verification, if requested
                            if [ $SKIPVERIFICATION -ne 1 ]; then
                                # Drop disk caches (for forcing the system to reload data from disk)
                                echo 3 > /proc/sys/vm/drop_caches 2>/dev/null ;

                                VERIFICATIONDIGEST=$(sha256sum "${WORKOUTPUT}/${WRITEFILE}" 2>/dev/null | cut -d' ' -f1) ;
                                if [ "$TARGETDIGEST" != "$VERIFICATIONDIGEST" ]; then
                                    log_error "Delta verification failed: cannot continue" ;
                                    return -3 ;
                                fi
                            fi

                            # Finalize ".update.tmp" files to ".update"
                            if [[ "$WRITEFILE" == *.update.tmp ]]; then
                                mv "${WORKOUTPUT}/${WRITEFILE}" "${WORKOUTPUT}/${WRITEFILE::-4}" ;
                                if [ $? -ne 0 ]; then
                                    log_error "Update file finalization failed: cannot continue" ;
                                    return -4 ;
                                fi
                            fi

                            # If here the delta was successfully applied and verified
                            USE_RESOURCE=0 ;
                        fi
                    else
                        # Get the temporary location of file depending on size
                        # (it populates variable TEMPLOCATION if successfull )
                        get_temp_for_size $DELTASIZE ;

                        if [ $? -ne 0 ]; then
                            log_error "Can't determine delta storage location: cannot continue" ;
                            return -5;
                        fi

                        DELTADIFF="$TEMPLOCATION" ;
                        get_asset "${PACKAGEFOLDER}/delta/${BASEFILE}/${EXDIGEST}.delta" > "$DELTADIFF" ;
                        DELTADIFFSIZE=$(wc -c "$DELTADIFF" 2>/dev/null | cut -d' ' -f1) ;

                        if [ $? -eq 0 ] && [ -f "$DELTADIFF" ] && [ $DELTADIFFSIZE -ne 0 ]; then
                            if [ $SIMULATION -eq 1 ]; then
                                log "+ Applying delta... (ACTUALLY PREVENTED BY SIMULATION MODE)" ;
                                if [ -f "$DELTADIFF" ]; then
                                    rm -rf "$DELTADIFF" ;
                                fi

                                # If here we can assume that delta can be successfully applied and verified
                                USE_RESOURCE=0 ;
                            else
                                # Flag the system for changes
                                if [ "$FILE" != "uboot.bin" ]; then
                                    REBOOTPENDING=1 ;
                                fi

                                # Clear target half ID when the first file is being touched
                                if [ "$PLATFORM" == "gemini" ]; then
                                    if [ $CLEAREDID -eq 0 ]; then
                                        CLEAREDID=1 ;
                                        if [ -x "/initram/dual-tool-id.sh" ]; then
                                            /initram/dual-tool-id.sh -b -t ${TARGETHALF} -c ;

                                            if [ $? -ne 0 ]; then
                                                log "# Cannot clear target half ID (error during operation)" ;
                                                return -1;
                                            fi
                                        else
                                            log "# Cannot clear target half ID (no script available)" ;
                                        fi
                                    fi
                                fi

                                # Apply delta
                                log "+ Applying delta..."
                                xdelta3 -d -f -D -R -S djw -s "${EXFILE}" "$DELTADIFF" "${WORKOUTPUT}/${WRITEFILE}" >/dev/null 2>/dev/null ;

                                if [ $? -ne 0 ]; then
                                    if [ -f "$DELTADIFF" ]; then
                                        rm -rf "$DELTADIFF" ;
                                    fi
                                    log_error "Error while applying patch: cannot continue" ;
                                    return -6 ;
                                else
                                    if [ -f "$DELTADIFF" ]; then
                                        rm -rf "$DELTADIFF" ;
                                    fi
                                fi

                                # Flush
                                sync ;

                                # Perform verification, if requested
                                if [ $SKIPVERIFICATION -ne 1 ]; then
                                    # Drop disk caches (for forcing the system to reload data from disk)
                                    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null ;

                                    VERIFICATIONDIGEST=$(sha256sum "${WORKOUTPUT}/${WRITEFILE}" 2>/dev/null | cut -d' ' -f1) ;
                                    if [ "$TARGETDIGEST" != "$VERIFICATIONDIGEST" ]; then
                                        log_error "Delta verification failed: cannot continue" ;
                                        return -7 ;
                                    fi
                                fi

                                # Finalize ".update.tmp" files to ".update"
                                if [[ "$WRITEFILE" == *.update.tmp ]]; then
                                    mv "${WORKOUTPUT}/${WRITEFILE}" "${WORKOUTPUT}/${WRITEFILE::-4}" ;
                                    if [ $? -ne 0 ]; then
                                        log_error "Update file finalization failed: cannot continue" ;
                                        return -8 ;
                                    fi
                                fi

                                # If here the delta was successfully applied and verified
                                USE_RESOURCE=0 ;
                            fi
                        else
                            # Remove temporary file, if any
                            if [ -f "$DELTADIFF" ]; then
                                rm -rf "$DELTADIFF" ;
                            fi
                        fi
                    fi
                fi

                if [ $USE_RESOURCE -eq 1 ]; then

                    # Log
                    log "! Can't retrieve or process delta file from package: attempt to retrieve resource from target..." ;

                    if [ $DOWNLOADPATCHES -eq 0 ]; then

                        if [ $SIMULATION -eq 1 ]; then
                            log "+ Applying target resource... (ACTUALLY PREVENTED BY SIMULATION MODE)" ;
                        else
                            # Flag the system for changes
                            if [ "$FILE" != "uboot.bin" ]; then
                                REBOOTPENDING=1 ;
                            fi

                            # Clear target half ID when the first file is being touched
                            if [ "$PLATFORM" == "gemini" ]; then
                                if [ $CLEAREDID -eq 0 ]; then
                                    CLEAREDID=1 ;
                                    if [ -x "/initram/dual-tool-id.sh" ]; then
                                        /initram/dual-tool-id.sh -b -t ${TARGETHALF} -c ;

                                        if [ $? -ne 0 ]; then
                                            log "# Cannot clear target half ID (error during operation)" ;
                                            return -1;
                                        fi
                                    else
                                        log "# Cannot clear target half ID (no script available)" ;
                                    fi
                                fi
                            fi

                            # Apply target resource
                            log "+ Applying target resource..."
                            get_asset "${PACKAGEFOLDER}/target/${BASEFILE}" > "${WORKOUTPUT}/${WRITEFILE}" 2>/dev/null ;

                            if [ $? -ne 0 ]; then
                                log_error "Error while applying target resource: cannot continue" ;
                                return -9 ;
                            fi

                            # Flush
                            sync ;

                            # Perform verification, if requested
                            if [ $SKIPVERIFICATION -ne 1 ]; then
                                # Drop disk caches (for forcing the system to reload data from disk)
                                echo 3 > /proc/sys/vm/drop_caches 2>/dev/null ;

                                VERIFICATIONDIGEST=$(sha256sum "${WORKOUTPUT}/${WRITEFILE}" 2>/dev/null | cut -d' ' -f1) ;
                                if [ "$TARGETDIGEST" != "$VERIFICATIONDIGEST" ]; then
                                    log_error "Delta verification failed: cannot continue" ;
                                    return -10 ;
                                fi
                            fi

                            # Finalize ".update.tmp" files to ".update"
                            if [[ "$WRITEFILE" == *.update.tmp ]]; then
                                mv "${WORKOUTPUT}/${WRITEFILE}" "${WORKOUTPUT}/${WRITEFILE::-4}" ;
                                if [ $? -ne 0 ]; then
                                    log_error "Update file finalization failed: cannot continue" ;
                                    return -11 ;
                                fi
                            fi
                        fi
                    else
                        # Get the temporary location of file depending on size
                        # (it populates variable TEMPLOCATION if successfull )
                        get_temp_for_size $TARGETSIZE ;

                        if [ $? -ne 0 ]; then
                            log_error "Can't determine resource storage location: cannot continue" ;
                            return -12;
                        fi

                        RESOURCETARGET="$TEMPLOCATION" ;
                        get_asset "${PACKAGEFOLDER}/target/${BASEFILE}" > "$RESOURCETARGET" ;
                        RESOURCETARGETSIZE=$(wc -c "$RESOURCETARGET" 2>/dev/null | cut -d' ' -f1) ;

                        if [ $? -eq 0 ] && [ -f "$RESOURCETARGET" ] && [ $RESOURCETARGETSIZE -ne 0 ]; then
                            if [ $SIMULATION -eq 1 ]; then
                                log "+ Applying target resource... (ACTUALLY PREVENTED BY SIMULATION MODE)" ;

                                if [ -f "$RESOURCETARGET" ]; then
                                    rm -rf "$RESOURCETARGET" ;
                                fi
                            else
                                # Flag the system for changes
                                if [ "$FILE" != "uboot.bin" ]; then
                                    REBOOTPENDING=1 ;
                                fi

                                # Clear target half ID when the first file is being touched
                                if [ "$PLATFORM" == "gemini" ]; then
                                    if [ $CLEAREDID -eq 0 ]; then
                                        CLEAREDID=1 ;
                                        if [ -x "/initram/dual-tool-id.sh" ]; then
                                            /initram/dual-tool-id.sh -b -t ${TARGETHALF} -c ;

                                            if [ $? -ne 0 ]; then
                                                log "# Cannot clear target half ID (error during operation)" ;
                                                return -1;
                                            fi
                                        else
                                            log "# Cannot clear target half ID (no script available)" ;
                                        fi
                                    fi
                                fi

                                # Apply target resource
                                log "+ Applying target resource..."
                                cp -f "$RESOURCETARGET" "${WORKOUTPUT}/${WRITEFILE}" >/dev/null 2>/dev/null;

                                if [ $? -ne 0 ]; then
                                    if [ -f "$RESOURCETARGET" ]; then
                                        rm -rf "$RESOURCETARGET" ;
                                    fi
                                    log_error "Error while applying target resource: cannot continue" ;
                                    return -13 ;
                                else
                                    if [ -f "$RESOURCETARGET" ]; then
                                        rm -rf "$RESOURCETARGET" ;
                                    fi
                                fi

                                # Flush
                                sync ;

                                # Perform verification, if requested
                                if [ $SKIPVERIFICATION -ne 1 ]; then
                                    # Drop disk caches (for forcing the system to reload data from disk)
                                    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null ;

                                    VERIFICATIONDIGEST=$(sha256sum "${WORKOUTPUT}/${WRITEFILE}" 2>/dev/null | cut -d' ' -f1) ;
                                    if [ "$TARGETDIGEST" != "$VERIFICATIONDIGEST" ]; then
                                        log_error "Delta verification failed: cannot continue" ;
                                        return -14 ;
                                    fi
                                fi

                                # Finalize ".update.tmp" files to ".update"
                                if [[ "$WRITEFILE" == *.update.tmp ]]; then
                                    mv "${WORKOUTPUT}/${WRITEFILE}" "${WORKOUTPUT}/${WRITEFILE::-4}" ;
                                    if [ $? -ne 0 ]; then
                                        log_error "Update file finalization failed: cannot continue" ;
                                        return -15 ;
                                    fi
                                fi
                            fi
                        else
                            if [ -f "$RESOURCETARGET" ]; then
                                rm -rf "$RESOURCETARGET" ;
                            fi

                            # Log
                            log "! Can't retrieve target resource from package: the file is not going to be updated";

                            # Set the flag for copy the assets from the current half, if it applies
                            COPYFROMEXISTING=1 ;
                        fi
                    fi
                fi
            else

                # Set the flag for copy the assets from the current half, if it applies
                COPYFROMEXISTING=1 ;
            fi
        else
            # Log
            log "! Can't find file from delta package: file is not going to be updated" ;

            # Set the flag for copy the assets from the current half, if it applies
            COPYFROMEXISTING=1 ;
        fi

        # Check if, for some reasons, the asset should be copied
        # from the current half
        if [ $COPYFROMEXISTING -eq 1 ] && [ ! -z "${DB_HALF}" ] && [ "$BASEFILE" != "uboot.bin" ]; then
            if [ ! -z "DB_HALF" ]; then

                diff -q "${FOLDER}/${FILE}" "${FOLDER}/${TARGETFILE}" >/dev/null 2>/dev/null ;
                if [ $? -eq 0 ]; then
                    # Log
                    log "+ No update available and no need to copy from current half (target file is already good)" ;
                else
                    if [ $SIMULATION -eq 1 ]; then
                        # Log
                        log "+ No update available: copying from current half... (ACTUALLY PREVENTED BY SIMULATION MODE)" ;
                    else
                        # Log
                        log "+ No update available: copying from current half..." ;

                        # Flag the system for changes
                        if [ "$FILE" != "uboot.bin" ]; then
                            REBOOTPENDING=1 ;
                        fi

                        # Clear target half ID when the first file is being touched
                        if [ "$PLATFORM" == "gemini" ]; then
                            if [ $CLEAREDID -eq 0 ]; then
                                CLEAREDID=1 ;
                                if [ -x "/initram/dual-tool-id.sh" ]; then
                                    /initram/dual-tool-id.sh -b -t ${TARGETHALF} -c ;

                                    if [ $? -ne 0 ]; then
                                        log "# Cannot clear target half ID (error during operation)" ;
                                        return -1;
                                    fi
                                else
                                    log "# Cannot clear target half ID (no script available)" ;
                                fi
                            fi
                        fi

                        # Copy file
                        cp -f "${FOLDER}/${FILE}" "${WORKOUTPUT}/${WRITEFILE}" ;

                        # Check result
                        if [ $? -ne 0 ]; then
                            log_error "Error while copying from current half: cannot continue" ;
                            return -16 ;
                        fi

                        # Flush
                        sync ;

                        # Perform verification, if requested
                        if [ $SKIPVERIFICATION -ne 1 ]; then
                            # Drop disk caches (for forcing the system to reload data from disk)
                            echo 3 > /proc/sys/vm/drop_caches 2>/dev/null ;

                            TARGETDIGEST=$(sha256sum "${FOLDER}/${FILE}" 2>/dev/null | cut -d' ' -f1) ;
                            VERIFICATIONDIGEST=$(sha256sum "${WORKOUTPUT}/${WRITEFILE}" 2>/dev/null | cut -d' ' -f1) ;
                            if [ "$TARGETDIGEST" != "$VERIFICATIONDIGEST" ]; then
                                log_error "Verification error while copying from current half: cannot continue" ;
                                return -17 ;
                            fi
                        fi
                    fi
                fi
            fi
        fi
    fi
}

usage () {
    cat << EOF
Usage: ${0##*/} [-hslnf] [-m <mode>] [-b <boot_folder> ] [ -d <data_folder> ] [ -o <output_folder> ] [ -r <max_ram_storage_size> ] <DELTA_PACKAGE>

Applies the delta package provided at <DELTA_PACKAGE> to system.

<DELTA_PACKAGE> could an URL in http:// or https:// format (the package content
is going to be fetched from web server), in sftp://, scp:// or ssh:// format (ssh:// and scp://
uses the SCP protocol for transferring files from SSH/SFTP server, while sftp:// makes use
of the SFTP protocol) or can be a local system folder (file:// format or plain path).

If sftp:// is going to be used, then an environment variable named SFTPOPTIONS can
be used for expressing extra paramters for the CURL command implementing the SFTP transfer,
if requested.

If ssh:// or scp:// is going to be used, then an enviroment variable named SSHPASS
can be used for expressing the password to be used for authentication to the SCP command.
For ssh:// and scp:// endpoints also an environment variable named SCPOPTIONS can be used for
expressing extra parameters for the SCP command, if requested.

If the current booting scheme (detected or forced via "-m" option) is partitions-based then
the system expects to found the "inactive boot partition" to be mounted at position
"<boot_folder>-inactive", otherwise the script terminates with error.

-h  Displays this help and exit
-s  Simulation mode: do not actually any file on system
-l  Download patches before applying them
-n  Do not verify data (fast but unsafe)
-f  Update boot loader (ATTENTION: could brick the system in case of errors)
-m  Forces the given boot scheme
    (<mode> can be "none", "files:a", "files:b" or "partitions")
-b  The folder containing boot assets (if not specified a guess is attempted based on platform)
-d  The folder containing non-boot assets (if not specified a guess is attempted based on platform)
-o  The output folder (if not specified, then the same <boot_folder> and <data_folder> are going
    to be used, based on asset type)
-x  Allow unsecure update
-y  The path to the public key to be used for verification
-r  For GEMINI platform only, it limits the maximum size of RAM to be used for assests storage
    (if not specified then half the available RAM is used at maximum)

RETURN VALUE:
    0: Success (no changes made)
    1-254: Error codes
    255: Success (some changes have been made and a reboot is pending)

EOF
}

echo "Aesys(R) Gemini(TM) xdelta processor" ;
echo "Copyright (C) Aesys S.p.A." ;
echo "Version 1.0.0.0" ;
echo ;

# Set default argument vars
COMMANDLINE="$@" ;
COMMANDNAME="$0" ;
SCRIPTNAME=$(basename "$0") ;
SIMULATION=0 ;
SKIPVERIFICATION=0 ;
FORCEDDUALBOOTSCHEME= ;
BOOTFOLDER= ;
DATAFOLDER= ;
OUTPUTFOLDER= ;
UPDATEBOOTLOADER=0 ;
REBOOTPENDING=0 ;
FORCEDMAXRAM=-1 ;
DOWNLOADPATCHES=0 ;
ALLOWUNSECURE=0 ;
VERIFICATIONKEY= ;
CLEAREDID=0 ;

# Determine the script's directory
SOURCE=${BASH_SOURCE[0]} ;
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  COMMANDDIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd ) ;
  SOURCE=$(readlink "$SOURCE") ;
  [[ $SOURCE != /* ]] && SOURCE=$COMMANDDIR/$SOURCE ;
done
COMMANDDIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd ) ;

# Determine temporary directory
HIST="$COMMANDDIR/.hist" ;

# Track execution
if [ ! -d "${HIST}" ]; then
    mkdir -p "${HIST}" 2>/dev/null ;
fi
if [ -d "${HIST}" ]; then
    mkdir -p "${HIST}" 2>/dev/null ;

    COMMANDLINE_OUTPUT="${HIST}/commandline.txt" ;
    echo "$COMMANDNAME $COMMANDLINE" >> "$COMMANDLINE_OUTPUT" 2>/dev/null ;
fi

OPTIND=1 ;
while getopts hslnfxm:b:d:o:r:y: opt; do
    case $opt in
        h)
            usage ;
            exit 0 ;
            ;;
        s)
            SIMULATION=1 ;
            ;;
        l)
            DOWNLOADPATCHES=1 ;
            ;;
        n)
            SKIPVERIFICATION=1 ;
            ;;
        f)
            UPDATEBOOTLOADER=1 ;
            ;;
        x)
            ALLOWUNSECURE=1 ;
            ;;
        m)
            FORCEDDUALBOOTSCHEME="${OPTARG}" ;
            ;;
        b)
            BOOTFOLDER="${OPTARG}" ;
            ;;
        d)
            DATAFOLDER="${OPTARG}" ;
            ;;
        o)
            OUTPUTFOLDER="${OPTARG}" ;
            ;;
        r)
            FORCEDMAXRAM=$(( "${OPTARG}" )) ;
            ;;
        y)
            VERIFICATIONKEY="${OPTARG}" ;
            ;;
        ?)
            echo >&2 ;
            usage >&2 ;
            exit 1;
            ;;
    esac
done
shift "$((OPTIND-1))" ;

# Avoid kernel messages to flood the console during this script
INITIAL_PRINT_LEVELS=$(sysctl kernel.printk | cut -d'=' -f2) ;
sysctl -w kernel.printk="2 4 1 7" >/dev/null 2>/dev/null ;

# Determine platform
PLATFORM= ;
KERNEL=$(uname -r) ;
if [[ "$KERNEL" == *gemini* ]]; then
    PLATFORM="gemini" ;
fi

# Pre-process settings depending on platform
if [ "$PLATFORM" == "gemini" ]; then
    if [ -f /data/.sys/unsecure-update.allowed ]; then
        ALLOWUNSECURE=1 ;
    fi

    if [ -z "$VERIFICATIONKEY" ]; then
        VERIFICATIONKEY="/initram/securefs.publickey.pem" ;
    fi
fi

# Check command line parameters
if [ -z "$BOOTFOLDER" ]; then
    if [ "$PLATFORM" == "gemini" ]; then
        BOOTFOLDER="/boot" ;

        if [ $SIMULATION -ne 1 ]; then
            # On Gemini the boot folder needs to be mounted R/W
            mount -o remount,rw "${BOOTFOLDER}" >/dev/null 2>/dev/null ;
            if [ $? -ne 0 ]; then
                log_error "GEMINI: Cannot mount boot-folder as read-write" ;
                clean_up ;
                exit 2 ;
            fi
        fi
    fi
fi

if [ ! -d "$BOOTFOLDER" ]; then
    log_error "Invalid or unspecified boot folder" ;
    clean_up ;
    exit 3 ;
fi

if [ -z "$DATAFOLDER" ]; then
    if [ "$PLATFORM" == "gemini" ]; then
        DATAFOLDER="/data/.sys" ;
    fi
fi

if [ ! -d "$DATAFOLDER" ]; then
    log_error "Invalid or unspecified data folder" ;
    clean_up ;
    exit 4 ;
fi;

if [ $ALLOWUNSECURE -ne 1 ]; then
    if [ -z "$VERIFICATIONKEY" ] || [ ! -f "$VERIFICATIONKEY" ]; then
        log_error "Verification key was not specified or cannot be found" ;
        clean_up ;
        exit 5 ;
    fi;
fi

# Check the availability of index.ini in DELTA_PACKAGE_FOLDER
PACKAGEFOLDER="$1" ;
PACKAGEINDEX=$(mktemp) ;
get_asset "$PACKAGEFOLDER/index.ini" > "$PACKAGEINDEX" ;
PACKAGEINDEXSIZE=$(wc -c "$PACKAGEINDEX" 2>/dev/null | cut -d' ' -f1) ;

if [ ! -f "$PACKAGEINDEX" ] || [ $PACKAGEINDEXSIZE -eq 0 ]; then
    log_error "Invalid or unspecified package folder" ;
    clean_up ;
    exit 6 ;
fi

# Get pre.sh script from package
PACKAGEPRE=$(mktemp) ;
get_asset "$PACKAGEFOLDER/pre.sh" > "$PACKAGEPRE" ;
PACKAGEPRESIZE=$(wc -c "$PACKAGEPRE" 2>/dev/null | cut -d' ' -f1) ;

# Get post.sh script from package
PACKAGEPOST=$(mktemp) ;
get_asset "$PACKAGEFOLDER/post.sh" > "$PACKAGEPOST" ;
PACKAGEPOSTSIZE=$(wc -c "$PACKAGEPOST" 2>/dev/null | cut -d' ' -f1) ;

# Prepare the output folder
if [ ! -z "$OUTPUTFOLDER" ] && [ "$OUTPUTFOLDER" != "$BOOTFOLDER" ] && [ "$OUTPUTFOLDER" != "$DATAFOLDER" ]; then
    rm -rf "$OUTPUTFOLDER" >/dev/null 2>/dev/null ;
    mkdir -p "$OUTPUTFOLDER" ;
fi

# Get kernel parameters
KERNEL_CMDLINE=`cat /proc/cmdline` ;

# Determine boot device (only if platform is set, just for avoiding dramatic results on working stations)
if [ ! -z "$PLATFORM" ]; then
    BOOT_PART=`echo ${KERNEL_CMDLINE} | sed -e 's/^.*root=//' -e 's/ .*$//'`
    BOOT_DEVICE=`echo ${BOOT_PART} | sed 's/..$//'`
fi

# Dump info
if [ $SIMULATION -eq 1 ]; then
    log "+------------------------------------------------+" ;
    log "|                 SIMULATION MODE                |" ;
    log "| The system is not going to be modified at all! |" ;
    log "+------------------------------------------------+" ;
    log ;
fi

if [ -z "$PLATFORM" ]; then
    log "Platform: (not specified)" ;
else
    log "Platform: ${PLATFORM^^}" ;
    log "Boot device: $BOOT_DEVICE" ;
    log "Boot partition: $BOOT_PART" ;
fi
log "Boot assets folder: $BOOTFOLDER" ;
log "Non-boot assets folder: $DATAFOLDER" ;
if [ -z "$OUTPUTFOLDER" ]; then
    log "Output folder: (not specified)" ;
else
    log "Output folder: $OUTPUTFOLDER" ;
fi
log ;

# Determine booting scheme
DB_HALF= ;
DB_MODE= ;
DB_FORCED_SINGLE= ;
DB_FORCED_ADDINFO= ;
if [ ! -z "$FORCEDDUALBOOTSCHEME" ]; then
    DB_FORCED_ADDINFO="(forced by user)" ;
    if [ "$FORCEDDUALBOOTSCHEME" == "partitions" ]; then
        DB_HALF="a" ;
        DB_MODE="partitions" ;
    elif [ "$FORCEDDUALBOOTSCHEME" == "files.a" ]; then
        DB_HALF="a" ;
        DB_MODE="files" ;
    elif [ "$FORCEDDUALBOOTSCHEME" == "files.b" ]; then
        DB_HALF="b" ;
        DB_MODE="files" ;
    elif [ "$FORCEDDUALBOOTSCHEME" == "none" ]; then
        DB_HALF= ;
        DB_MODE= ;
    else
        log_error "Invalid boot scheme partition force flag" ;
        clean_up ;
        exit 9 ;
    fi
else
    DB_CMDLINE_CURRENTHALF=`echo ${KERNEL_CMDLINE} | grep "db_active_half="` ;
    DB_CMDLINE_MODE=`echo ${KERNEL_CMDLINE} | grep "db_mode="` ;
    DB_CMDLINE_FORCED_SINGLE=`echo ${KERNEL_CMDLINE} | grep "db_force_single"` ;

    if [ ! -z "${DB_CMDLINE_CURRENTHALF}" ] && [ ! -z "${DB_CMDLINE_MODE}" ]; then
        DB_HALF=`echo $DB_CMDLINE_CURRENTHALF | sed -e 's/^.*db_active_half=//' -e 's/ .*$//'` ;
        DB_MODE=`echo $DB_CMDLINE_MODE | sed -e 's/^.*db_mode=//' -e 's/ .*$//'` ;
        if [ ! -z "$DB_CMDLINE_FORCED_SINGLE" ]; then
            DB_FORCED_SINGLE="(forced single boot)" ;
        fi
    fi
fi

# Determine target half
TARGETHALF= ;
if [[ "$DB_HALF" == "a" ]]; then
    if [ -z "$DB_FORCED_SINGLE" ]; then
        TARGETHALF="b" ;
    else
        TARGETHALF="a" ;
    fi
else
    TARGETHALF="a" ;
fi

# Dump detected booting scheme
BOOTFOLDEROTHER= ;
if [ -z "$DB_HALF" ]; then
    log "Booting scheme: SINGLE boot $DB_FORCED_ADDINFO" ;
elif [ "${DB_MODE}" == "partitions" ]; then
    log "Booting scheme: DUAL boot (partitions-based, current half: ${DB_HALF^^}) $DB_FORCED_SINGLE $DB_FORCED_ADDINFO" ;
    BOOTFOLDEROTHER="${BOOTFOLDER}-inactive" ;

    if [ ! -d ${BOOTFOLDEROTHER} ]; then
        log_error "Cannot access the inactive-half boot partition: cannot continue" ;
        clean_up ;
        exit 10;
    fi

    if [ $SIMULATION -ne 1 ]; then
        # On Gemini the boot folder needs to be mounted R/W
        if [ "$PLATFORM" == "gemini" ]; then
            mount -o remount,rw "${BOOTFOLDEROTHER}" >/dev/null 2>/dev/null ;
            if [ $? -ne 0 ]; then
                log_error "GEMINI: Cannot mount inactive boot folder as read-write" ;
                clean_up ;
                exit 11 ;
            fi
        fi
    fi
else
    log "Booting scheme: DUAL boot (files-based, current half: ${DB_HALF^^}) $DB_FORCED_SINGLE $DB_FORCED_ADDINFO" ;
fi
log

# Verify package signature, if requested
if [ $ALLOWUNSECURE -ne 1 ]; then

    # Check the availability of index.ini signature in DELTA_PACKAGE_FOLDER, if requested
    PACKAGEINDEXSIG=$(mktemp);
    get_asset "$PACKAGEFOLDER/index.ini.sig" > "$PACKAGEINDEXSIG"
    PACKAGEINDEXSIGSIZE=$(wc -c "$PACKAGEINDEXSIG" 2>/dev/null | cut -d' ' -f1) ;

    if [ ! -f "$PACKAGEINDEXSIG" ] || [ $PACKAGEINDEXSIGSIZE -eq 0 ]; then
        log_error "Cannot find package signature" ;
        clean_up ;
        exit 7 ;
    fi

    # Package signature verification
    openssl dgst -keyform PEM -verify "${VERIFICATIONKEY}" -sha256 -signature "$PACKAGEINDEXSIG" "$PACKAGEINDEX" >/dev/null 2>/dev/null
    if [ $? -ne 0 ]; then
        log_error "Cannot verify package signature" ;
        clean_up ;
        exit 8 ;
    else
        log "Package signature was OK" ;
    fi
else
    log_warning "Package security check disabled by user choice" ;
fi
log

# Prepare support files for boot loader update
UBOOTBIN=$(mktemp) ;
UBOOTBINEX=$(mktemp) ;

# Execute pre.sh, if any
if [ -f "$PACKAGEPRE" ] && [ $PACKAGEPRESIZE -ne 0 ]; then
    if [ $SIMULATION -eq 1 ]; then
        # Log
        log "Executing pre.sh script... (ACTUALLY PREVENTED BY SIMULATION MODE)" ;
    else
        # Log
        log "Executing pre.sh script..." ;

        # Flag the system for (possible) changes
        REBOOTPENDING=1 ;

        # Execute script
        source "$PACKAGEPRE" ;
    fi
    log ;
fi

# Manage bootloader update, if requested
if [ -z "$PLATFORM" ]; then
    log_warning "Boot loader check disabled on non-identified platforms" ;
    log ;
elif [ $UPDATEBOOTLOADER -ne 1 ]; then
    log_warning "Boot loader check disabled by user choice" ;
    log ;
elif [ -z "$BOOT_DEVICE" ]; then
    log_error "Cannot perform boot loader check due to unavailability of boot device" ;
    clean_up ;
    exit 12 ;
else
    delta_file "$BOOT_DEVICE" "uboot.bin" ;

    UBOOTBINSIZE=$(wc -c "$UBOOTBIN" 2>/dev/null | cut -d' ' -f1) ;
    if [ ! -f "$UBOOTBIN" ] || [ $UBOOTBINSIZE -eq 0 ]; then
        log "+ No update available" ;
    else
        # Flag the system for changes
        REBOOTPENDING=1 ;

        # Flash the bootloader
        dd if="$UBOOTBIN" of="$BOOT_DEVICE" bs=1024 seek=32 >/dev/null 2>/null ;

        if [ $? -ne 0 ]; then
            log_error "Error while patching boot loader: the system could be BRICKED!" ;
            clean_up ;
            exit 13 ;
        fi

        # Flush
        sync ;

        # Perform verification, if requested
        if [ $SKIPVERIFICATION -ne 1 ]; then
            # Drop disk caches (for forcing the system to reload data from disk)
            echo 3 > /proc/sys/vm/drop_caches 2>/dev/null ;

            TARGETDIGEST=$(sha256sum "$UBOOTBIN" 2>/dev/null | cut -d' ' -f1);
            TARGETSIZE=$(wc -c "$UBOOTBIN" 2>/dev/null | cut -d' ' -f1) ;

            VERIFICATIONDIGEST=$(dd if=${BOOT_DEVICE} bs=1024 skip=32 iflag=count_bytes count=$TARGETSIZE 2>/dev/null | sha256sum 2>/dev/null | cut -d' ' -f1);

            if [ "$TARGETDIGEST" != "$VERIFICATIONDIGEST" ]; then
                log_error "Delta verification failed for boot loader: the system could be BRICKED!" ;
                clean_up ;
                exit 14 ;
            fi
        fi
    fi
fi

# Determine the list of files in boot folder to be updated
FILES=( $(ls -1p "${BOOTFOLDER}" | grep -v "/") ) ;
for f in ${FILES[@]}; do

    # Apply delta to current file, if any
    delta_file "${BOOTFOLDER}" "${f}" "${BOOTFOLDEROTHER}";

    # Check result
    if [ $? -ne 0 ]; then
        log_error "Error detected while processing boot files: cannot continue" ;
        clean_up ;
        exit 15;
    fi
done

# Determine the list of files in data folder to be updated
# (all .squashfs* files, for also handling .squashfs.a and .squashfs.b)
FILES=( $(ls -1p "${DATAFOLDER}"/*.squashfs* 2>/dev/null) ) ;
for f in ${FILES[@]}; do

    if [[ "${f}" != *".update" ]] && [[ "${f}" != *".update.tmp" ]]; then
        # Apply delta to current file, if any
        delta_file "${DATAFOLDER}" "$(basename ${f})" ;

        # Check result
        if [ $? -ne 0 ]; then
            log_error "Error detected while processing data files: cannot continue" ;
            clean_up ;
            exit 16;
        fi
    fi
done
log ;

# Execute post.sh, if any
if [ -f "$PACKAGEPOST" ] && [ $PACKAGEPOSTSIZE -ne 0 ]; then
    if [ $SIMULATION -eq 1 ]; then
        # Log
        log "Executing post.sh script... (ACTUALLY PREVENTED BY SIMULATION MODE)" ;
    else
        # Log
        log "Executing post.sh script..." ;

        # Flag the system for (possible) changes
        REBOOTPENDING=1 ;

        # Execute script
        source "$PACKAGEPOST" ;
    fi
    log ;
fi

# Synchonize half ID and flag the system for attempting half switch, if requested
if [ $REBOOTPENDING -eq 1 ]; then
    if [ "$PLATFORM" == "gemini" ]; then
        if [ $SIMULATION -eq 1 ]; then
            # Log
            log "Synchronizing target half ID... (ACTUALLY PREVENTED BY SIMULATION MODE)" ;
        else
            log "Synchronizing target half ID..." ;
            if [ -x "/initram/dual-tool-id.sh" ]; then
                /initram/dual-tool-id.sh -b -t ${TARGETHALF} -s ;

                if [ $? -ne 0 ]; then
                    log_error "Cannot synchronize target half ID (error during operation)" ;
                    clean_up ;
                    exit 9 ;
                fi
            else
                log_warning "Cannot synchronize target half ID (no script available)" ;
            fi

            log "Flagging system for attempting half switching..." ;
            fw_setenv db_attempt_switch 1 ;

            if [ $? -ne 0 ]; then
                log_error "Cannot flag the system for half switch" ;
                clean_up ;
                exit 10 ;
            fi
        fi
    fi
fi

# Clean-up
clean_up ;

# Manage exit status
if [ $REBOOTPENDING -eq 1 ]; then

    if [ $SIMULATION -ne 1 ]; then
        log "*** REBOOT PENDING FOR FINISHING UP THE UPDATE *** " ;
    fi

    exit 255;
fi
