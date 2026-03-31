#!/bin/bash

# Functions declaration
log () {
    if [ $SILENT -eq 1 ] || [ $BATCH -eq 1 ]; then
        if [ "$2" != "force-batch" ]; then
            return 0;
        fi
    fi

    if [ "$2" == "force-batch" ]; then
        echo "+ $1" ;
    else
        echo "$1" ;
    fi
}

log_warning () {
    if [ $SILENT -eq 1 ] || [ $BATCH -eq 1 ]; then
        if [ "$2" != "force-batch" ]; then
            return 0;
        fi
    fi

    if [ "$2" == "force-batch" ]; then
        echo "! WARNING: $1" >&2 ;
    else
        echo "WARNING: $1" >&2 ;
    fi
}

log_error () {
    if [ $SILENT -eq 1 ] || [ $BATCH -eq 1 ]; then
        if [ "$2" != "force-batch" ]; then
            return 0;
        fi
    fi

    if [ "$2" == "force-batch" ]; then
        echo "# ERROR: $1" >&2 ;
    else
        echo >&2 ;
        echo "ERROR: $1" >&2 ;
        echo >&2 ;
    fi
}

process_file () {
    FOLDER="${1}" ;
    FILE="${2}" ;

    # Log
    log "Processing file ${FILE}..."

    if [ "${DB_MODE}" == "partitions" ]; then
        if [[ "$FOLDER" == *"boot"* ]]; then
            if [[ "$FILE" == *".a" ]] || [[ "$FILE" == *".b" ]]; then
                log "- Skipped: half-based file while in dual boot (partitions-based) scheme" ;
                return 0 ;
            fi
        else
            if [[ "$FILE" == *".a" ]] || [[ "$FILE" == *".b" ]]; then
                if [[ $FILE != *."${TARGETHALF}" ]]; then
                    log "- Skipped: not target-half file while in dual boot (partitions-based) scheme" ;
                    return 0 ;
                fi
            else
                log "- Skipped: non half-based file while in dual boot (partitions-based) scheme" ;
                return 0 ;
            fi
        fi
    else
        if [[ "$FILE" != *".a" ]] && [[ "$FILE" != *".b" ]]; then
            log "- Skipped: not half-based file while in dual boot (files-based) scheme" ;
            return 0 ;
        else
            if [[ $FILE != *".${TARGETHALF}" ]]; then
                log "- Skipped: not target-half file while in dual boot (files-based) scheme" ;
                return 0 ;
            fi
        fi
    fi

    # Manage .update files
    FILETARGET="" ;
    if [[ "$FILE" == *.squashfs.* ]]; then
        if [ -f "/data/.sys/$FILE.update" ]; then
            log "! Considering file /data/.sys/$FILE.update..." ;
            FOLDER="/data/.sys" ;
            FILETARGET="$FILE.update" ;
        else
            FILETARGET="$FILE";
        fi
    else
        FILETARGET="$FILE";
    fi

    # Compare source and target (managing update files, which may appear in dual boot scenario forced to work as single boot)
    FILEDIGEST="" ;
    if [ ! -f "${FOLDER}/${FILETARGET}" ]; then
        FILEDIGEST="(missing)";
    else
        FILEDIGEST=$(sha256sum "${FOLDER}/${FILETARGET}" 2>/dev/null | cut -d' ' -f1);
    fi

    # Check result
    if [ $? -ne 0 ]; then
        log "# Error while calculating file digest" ;
        return -1;
    fi

    # Update ID
    ID=$(echo "$ID:$FILEDIGEST" | sha256sum 2>/dev/null | cut -d' ' -f1);

    # Log
    log "+ File digest: ${FILEDIGEST}" ;
    log "+ Update half ID: ${ID}" ;
    return 0;
}

usage () {
    cat << EOF
Usage: ${0##*/} [-hcsbo] [-t <target>]

Tool for generating dual-boot ID.

If invoked without parameters then the ID is calculated and dumped on screen only.

-h  Displays this help and exit
-c  Clears the ID file from target half, if any, and exit
-s  Writes the ID file to target half
-b  Batch mode: only print relevant info (using batch formatting)
-o  Silent run: only print ID is going to be printed on stdout, nothing else
-t  Specifies the target half
    (<target> can be "a" or "b"; if not specified or invalid then the current half is assumed)

RETURN VALUE:
    0: Success
    1-255: Error codes

EOF
}

# Set default argument vars
COMMANDLINE="$@" ;
COMMANDNAME="$0" ;
SCRIPTNAME=$(basename "$0") ;
CLEAR=0 ;
SYNC=0 ;
SILENT=0 ;
BATCH=0 ;

# Determine the script's directory
SOURCE=${BASH_SOURCE[0]} ;
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  COMMANDDIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd ) ;
  SOURCE=$(readlink "$SOURCE") ;
  [[ $SOURCE != /* ]] && SOURCE=$COMMANDDIR/$SOURCE ;
done
COMMANDDIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd ) ;

OPTIND=1 ;
while getopts hcsbot: opt; do
    case $opt in
        h)
            usage ;
            exit 0 ;
            ;;
        c)
            CLEAR=1 ;
            ;;
        s)
            SYNC=1 ;
            ;;
        b)
            BATCH=1 ;
            ;;
        o)
            SILENT=1 ;
            ;;
        t)
            TARGETHALF="${OPTARG}" ;
            ;;
        ?)
            echo >&2 ;
            usage >&2 ;
            exit 1;
            ;;
    esac
done
shift "$((OPTIND-1))" ;

log "Aesys(R) Gemini(TM) dual-boot-id tool" ;
log "Copyright (C) Aesys S.p.A." ;
log "Version 1.0.0.0" ;
log ;

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
    log_error "The system is not dual-boot based. Cannot continue." ;
    exit 2;
fi

# Dump detected booting scheme
if [ "${DB_MODE}" == "partitions" ]; then
    log "Booting scheme: DUAL boot (partitions-based, current half: ${DB_HALF^^})" ;
else
    log "Booting scheme: DUAL boot (files-based, current half: ${DB_HALF^^})" ;
fi
log

# Determine target half and dump
if [ -z "$TARGETHALF" ]; then
    TARGETHALF="${DB_HALF}" ;
else
    if [ "$TARGETHALF" != "a" ] && [ "$TARGETHALF" != "b" ]; then
        log_warning "Specified half $TARGETHALF is not valid: reverting to current half" ;
        TARGETHALF="${DB_HALF}" ;
    fi
fi
log "TARGET HALF IS: ${TARGETHALF^^}" ;
log

# Determine target boot folder and check access, if requested
TARGETBOOTFOLDER="" ;
if [ "${DB_MODE}" == "partitions" ]; then
    TARGETBOOTFOLDER="/boot-inactive" ;
else
    TARGETBOOTFOLDER="/boot" ;
fi

# Check access to the target boot folder
if [ ! -d "${TARGETBOOTFOLDER}" ]; then
    log_error "Cannot access the target boot partition: cannot continue" ;
    exit 3;
fi

# Check access to /data/.sys folder
if [ ! -d "/data/.sys" ]; then
    log_error "Cannot access the data partition: cannot continue" ;
    exit 4;
fi

# Clear the file if requested
if [ $CLEAR -eq 1 ]; then
    log "Clearing half file ID from data partition..." "force-batch" ;
    if [ -f "/data/.sys/${TARGETHALF}.id" ]; then
        rm -f "/data/.sys/${TARGETHALF}.id" ;

        if [ $? -ne 0 ]; then
            log_error "Cannot clear file ID from data partition" "force-batch" ;
            exit 5;
        fi

        sync ;

        log "Target half file ID cleared from data partition" "force-batch" ;
        log ;
    else
        log "Target half file ID did not already exist" "force-batch" ;
        log ;
    fi

    exit 0;
fi

# Declare vars
ID="" ;

# Determine the list of files in boot folder to be updated
FILES=( $(ls -1p "${TARGETBOOTFOLDER}" | grep -v "/") ) ;
for f in ${FILES[@]}; do

    # Apply delta to current file, if any
    process_file "${TARGETBOOTFOLDER}" "$(basename ${f})" ;

    # Check result
    RES=$? ;
    if [ $RES -lt 0 ] || [ $RES -gt 128 ]; then
        log_error "Error detected while processing boot files: cannot continue" ;
        exit 6;
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
        exit 7;
    fi
done
log ;

# Write ID to disk, if requested
if [ $SYNC -eq 1 ]; then
    log "Writing half file ID to data partition..." "force-batch" ;

    echo "$ID" > "/data/.sys/${TARGETHALF}.id" ;

    if [ $? -ne 0 ]; then
        log_error "Cannot write file ID to data partition" "force-batch" ;
        exit 8;
    fi

    log "Target half file ID successfully written to data partition" "force-batch" ;
    log ;

    sync ;
fi

# Finalize run
if [ $SILENT -eq 1 ]; then
    echo $ID ;
else
    log "TARGET HALF ID IS: ${ID}" ;
fi;
log ;
