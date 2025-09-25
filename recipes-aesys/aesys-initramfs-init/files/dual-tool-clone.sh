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

    if [ $SYNC -eq 1 ]; then
        # Ensure boot folder is remounted RO
        if [ ! -z "/boot" ] && [ -d "/boot" ]; then
            mount -o remount,ro "/boot" >/dev/null 2>/dev/null ;
        fi

        # Ensure inactive boot folder is remounted RO
        if [ ! -z "/boot-inactive" ] && [ -d "/boot-inactive" ]; then
            mount -o remount,ro "/boot-inactive" >/dev/null 2>/dev/null ;
        fi

         # Restore initial kernel printk levels
        if [ ! -z "$INITIAL_PRINT_LEVELS" ]; then
            sysctl -w kernel.printk="$INITIAL_PRINT_LEVELS" >/dev/null 2>/dev/null;
        fi
    fi
}


process_file () {
    FOLDER="${1}" ;
    FILE="${2}" ;

    # Log
    log "Processing file ${FILE}..."

    # Determine target file and folder
    TARGETFOLDER= ;
    TARGETFILE= ;
    if [[ "$FILE" == *".a" ]]; then
        TARGETFILE="${FILE::-2}.b" ;
    elif [[ "$FILE" == *".b" ]]; then
        TARGETFILE="${FILE::-2}.a" ;
    else
        TARGETFILE="${FILE}" ;
    fi

    if [ "${DB_MODE}" == "partitions" ]; then
        if [[ "$FOLDER" == *"boot"* ]]; then
            if [[ "$FILE" == *".a" ]] || [[ "$FILE" == *".b" ]]; then
                log "+ Skipped: half-based file while in dual boot (partitions) scheme" ;
                return 0 ;
            fi
            TARGETFOLDER="/boot-inactive" ;
        else
            if [[ "$FILE" == *".a" ]] || [[ "$FILE" == *".b" ]]; then
                if [[ $FILE != *."${DB_HALF}" ]]; then
                    log "+ Skipped: not current-half file while in dual (partitions-based) boot scheme" ;
                    return 0 ;
                fi
            else
                log "+ Skipped: non half-based file while in dual boot (partitions) scheme" ;
                return 0 ;
            fi
            TARGETFOLDER="$FOLDER" ;
        fi
    else
        TARGETFOLDER="$FOLDER" ;
        if [[ "$FILE" != *".a" ]] && [[ "$FILE" != *".b" ]]; then
            log "+ Skipped: not half-based file while in dual boot (files) scheme" ;
            return 0 ;
        else
            if [[ $FILE != *".${DB_HALF}" ]]; then
                log "+ Skipped: not current-half file while in dual (files-based) boot scheme" ;
                return 0 ;
            fi
        fi
    fi

    # Compare source and target
    COMPARE=0 ;
    if [ ! -f "${TARGETFOLDER}/${TARGETFILE}" ]; then
        COMPARE=1 ;
    else
        diff -q "${FOLDER}/${FILE}" "${TARGETFOLDER}/${TARGETFILE}" >/dev/null 2>/dev/null ;
        COMPARE=$? ;
    fi

    # Process comparing
    if [ $COMPARE -eq 0 ]; then
        return 0 ;
    else
        if [ $SYNC -eq 0 ]; then
            log "+ File needs sync" ;
            return 1;
        else
            log "+ Syncing file..." ;

            # Clear target half ID when the first file is being touched
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

            # Copy file
            cp -f "${FOLDER}/${FILE}" "${TARGETFOLDER}/${TARGETFILE}" >/dev/null 2>/dev/null ;

            if [ $? -ne 0 ]; then
                log "# Error while syncing files" ;
                return -2;
            fi

            # Flush
            sync ;

            # Perform verification, if requested
            if [ $SKIPVERIFICATION -ne 1 ]; then
                # Drop disk caches (for forcing the system to reload data from disk)
                echo 3 > /proc/sys/vm/drop_caches 2>/dev/null ;

                diff -q "${FOLDER}/${FILE}" "${TARGETFOLDER}/${TARGETFILE}" >/dev/null 2>/dev/null ;
                if [ $? -ne 0 ]; then
                    log_error "Data verification failed: cannot continue" ;
                    return -3 ;
                fi
            fi

            return 1;
        fi
    fi
}

usage () {
    cat << EOF
Usage: ${0##*/} [-hsn]

Tool for cloning environments in dual-boot scenario.

If invoked without parameters then only a compare is performed for determining if the
content of the dual boot halves equals or not.

-h  Displays this help and exit
-s  Synchronizes the active half onto the inactive half, if requested.
-n  Do not verify data (fast but unsafe)

RETURN VALUE:
    0: Success (no differences detected or no changes made)
    1-254: Error codes
    255: Success (some changes have been made or are requested to be made)

EOF
}

echo "Aesys(R) Gemini(TM) dual-boot tool" ;
echo "Copyright (C) Aesys S.p.A." ;
echo "Version 1.0.0.0" ;
echo ;

# Set default argument vars
COMMANDLINE="$@" ;
COMMANDNAME="$0" ;
SCRIPTNAME=$(basename "$0") ;
SYNC=0 ;
SKIPVERIFICATION=0 ;
CLEAREDID=0 ;

# Determine the script's directory
SOURCE=${BASH_SOURCE[0]} ;
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  COMMANDDIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd ) ;
  SOURCE=$(readlink "$SOURCE") ;
  [[ $SOURCE != /* ]] && SOURCE=$COMMANDDIR/$SOURCE ;
done
COMMANDDIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd ) ;

OPTIND=1 ;
while getopts hsn opt; do
    case $opt in
        h)
            usage ;
            exit 0 ;
            ;;
        s)
            SYNC=1 ;
            ;;
        n)
            SKIPVERIFICATION=1 ;
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

# Check access to /data/.sys folder
if [ ! -d "/data/.sys" ]; then
    log_error "Cannot access the data partition: cannot continue" ;
    exit 2;
fi

# Check access to /boot folder
if [ $SYNC -eq 1 ]; then
    mount -o remount,rw "/boot" >/dev/null 2>/dev/null ;
    if [ $? -ne 0 ]; then
        log_error "Cannot mount boot-folder as read-write" ;
        clean_up ;
        exit 3 ;
    fi
fi

# Get kernel parameters
KERNEL_CMDLINE=`cat /proc/cmdline` ;

# Determine booting scheme
DB_HALF= ;
DB_MODE= ;
DB_CMDLINE_CURRENTHALF=`echo ${KERNEL_CMDLINE} | grep "db_active_half="` ;
DB_CMDLINE_MODE=`echo ${KERNEL_CMDLINE} | grep "db_mode="` ;

if [ ! -z "${DB_CMDLINE_CURRENTHALF}" ] && [ ! -z "${DB_CMDLINE_MODE}" ]; then
    DB_HALF=`echo $DB_CMDLINE_CURRENTHALF | sed -e 's/^.*db_active_half=//' -e 's/ .*$//'` ;
    DB_MODE=`echo $DB_CMDLINE_MODE | sed -e 's/^.*db_mode=//' -e 's/ .*$//'` ;
fi

if [ -z "$DB_HALF" ] || [ -z "$DB_MODE" ]; then
    log_error "The system is not dual-boot based, or the current half cannot be determined. Cannot continue." ;
    clean_up ;
    exit 4;
fi

# Dump detected booting scheme and perform additional checks, if requested
if [ "${DB_MODE}" == "partitions" ]; then
    log "Booting scheme: DUAL boot (partitions-based, current half: ${DB_HALF^^})" ;

    if [ ! -d "/boot-inactive" ]; then
        log_error "Cannot access the inactive-half boot partition: cannot continue" ;
        clean_up ;
        exit 5;
    fi

    if [ $SYNC -eq 1 ]; then
        mount -o remount,rw "/boot-inactive" >/dev/null 2>/dev/null ;
        if [ $? -ne 0 ]; then
            log_error "Cannot mount inactive boot-folder as read-write" ;
            clean_up ;
            exit 6 ;
        fi
    fi
else
    log "Booting scheme: DUAL boot (files-based, current half: ${DB_HALF^^})" ;
fi
log

# Determine target half
TARGETHALF= ;
if [[ "$DB_HALF" == "a" ]]; then
    TARGETHALF="b" ;
else
    TARGETHALF="a" ;
fi

# Declare vars
PENDINGCHANGES=0 ;

# Determine the list of files in boot folder to be updated
FILES=( $(ls -1p "/boot" | grep -v "/") ) ;
for f in ${FILES[@]}; do

    # Apply delta to current file, if any
    process_file "/boot" "$(basename ${f})" ;

    # Check result
    RES=$? ;
    if [ $RES -lt 0 ] || [ $RES -gt 128 ]; then
        log_error "Error detected while processing boot files: cannot continue" ;
        clean_up ;
        exit 7;
    elif [ $RES -gt 0 ]; then
        PENDINGCHANGES=1 ;
    fi
done
log ;

# Determine the list of files in data folder to be updated
# (all .squashfs* files, for also handling .squashfs.a and .squashfs.b)
FILES=( $(ls -1p "/data/.sys"/*.squashfs* 2>/dev/null) ) ;
for f in ${FILES[@]}; do

    # Apply delta to current file, if any
    process_file "/data/.sys" "$(basename ${f})" ;

    # Check result
    RES=$? ;
    if [ $RES -lt 0 ] || [ $RES -gt 128 ]; then
        log_error "Error detected while processing data files: cannot continue" ;
        clean_up ;
        exit 8;
    elif [ $RES -gt 0 ]; then
        PENDINGCHANGES=1 ;
    fi
done
log ;

# Clean-up
clean_up ;

# Manage exit status
if [ $PENDINGCHANGES -eq 1 ]; then
    if [ $SYNC -eq 1 ]; then

        # Synchonize half ID
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
        log ;

        log "INACTIVE HALF WAS SYNCHRONIZED WITH ACTIVE HALF" ;
    else
        log "INACTIVE HALF NEEDS SYNCHRONIZATION" ;
    fi
    log;
    exit 255;
else
    if [ $SYNC -eq 1 ]; then
        log "Inactive half was already synchronized with active half: no changes made" ;
    else
        log "Inactive half is already sychronized with active half: no synchronization needed" ;
    fi
    log ;
fi
