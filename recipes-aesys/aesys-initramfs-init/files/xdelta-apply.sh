#!/bin/bash

# Functions declaration
log () {
    echo $1 ;
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
}

get_asset () {
    URL="$1" ;

    if [[ "$URL" == http://* ]] || [[ "$URL" == https://* ]]; then
        wget -O - "$URL" 2>/dev/null ;
    elif [[ "$URL" == sftp://* ]] || [[ "$URL" == ssh://* ]]; then
        # Environment variable SSHPASS should contain the full `sshpass` command, if requested
        $SSHPASS scp -O "${URL#*://}" /dev/stdout 2>/dev/null ;
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
    if [ -z "${DB_HALF}" ] || [ "${DB_MODE}" == "partitions" ]; then
        if [[ $FILE == *.a ]] || [[ $FILE == *.b ]]; then
            log "+ Skipped: half-based file while in single of dual (partitions-based) boot scheme" ;
        else
            BASEFILE="$FILE" ;

            if [ -z "${DB_HALF}" ]; then
                # Special treatment for non-boot assets, if in single boot partition mode
                # (in this case they are updated by system start-up script
                # since they might be in use, and so not directly updatable)
                if [ "$FILE" == "rootfs.squashfs" ] || [ "$FILE" == "app.bin" ]; then
                    TARGETFILE="$FILE.update.tmp" ;
                    OTHERFOLDER="$DATAFOLDER" ;
                else
                    TARGETFILE="$FILE" ;
                fi
            else
                TARGETFILE="$FILE" ;
            fi
        fi
    else
        if [[ $FILE != *.${DB_HALF} ]]; then
            log "+ Skipped: not current-half file while in dual (files-based) boot scheme" ;
        else
            BASEFILE="${FILE::-2}" ;
            if [ "${DB_HALF}" == "a" ]; then
                TARGETFILE="$BASEFILE.b" ;
            else
                TARGETFILE="$BASEFILE.a" ;
            fi
        fi
    fi

    if [ ! -z "$TARGETFILE" ] && [ ! -z "$BASEFILE" ]; then

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

            TARGETDIGEST=$(echo "$TARGETENTRY" | cut -d'=' -f2) ;

            # Calculate existing file digest
            EXDIGEST=$(sha256sum "${FOLDER}/${FILE}" 2>/dev/null | cut -d' ' -f1) ;

            if [ "$TARGETDIGEST" != "$EXDIGEST" ]; then

                # Log
                log "+ File needs update" ;

                # Check if the file exists as a delta in the package
                DELTADIFF=$(mktemp) ;
                get_asset "${PACKAGEFOLDER}/delta/${BASEFILE}/${EXDIGEST}.delta" > "$DELTADIFF" ;

                if [ $? -eq 0 ] && [ -f "$DELTADIFF" ]; then
                    log "+ Applying delta..."
                    if [ $XDELTA -eq 1 ]; then
                        xdelta patch -p "$DELTADIFF" "${FOLDER}/${FILE}" "${WORKOUTPUT}/${TARGETFILE}" >/dev/null 2>/dev/null ;
                    else
                        xdelta3 -d -f -D -R -S djw -s "${FOLDER}/${FILE}" "$DELTADIFF" "${WORKOUTPUT}/${TARGETFILE}" >/dev/null 2>/dev/null ;
                    fi

                    if [ $? -ne 0 ]; then
                        rm -rf "$DELTADIFF" ;
                        log_error "# Error while applying patch: cannot continue" ;
                        return -1 ;
                    else
                        rm -rf "$DELTADIFF" ;
                    fi

                    # Flush
                    sync ;

                    # Drop disk caches (for forcing the system to reload data from disk)
                    echo 3 > /proc/sys/vm/drop_caches ;

                    # Perform verification, if requested
                    if [ $SKIPVERIFICATION -ne 1 ]; then
                        VERIFICATIONDIGEST=$(sha256sum "${WORKOUTPUT}/${TARGETFILE}" 2>/dev/null | cut -d' ' -f1) ;
                        if [ "$TARGETDIGEST" != "$VERIFICATIONDIGEST" ]; then
                            log_error "# Delta verification failed: cannot continue" ;
                            return -2 ;
                        fi
                    fi

                    # Finalize ".update.tmp" files to ".update"
                    if [[ "$TARGETFILE" == *.update.tmp ]]; then
                        mv "${WORKOUTPUT}/${TARGETFILE}" "${WORKOUTPUT}/${TARGETFILE::-4}" ;
                        if [ $? -ne 0 ]; then
                            log_error "# Update file finalization failed: cannot continue" ;
                            return -2 ;
                        fi
                    fi
                else
                    # Log
                    log_warning "! Can't retrieve file from delta package: file is not going to be updated" ;

                    # Set the flag for copy the assets from the current half, if it applies
                    COPYFROMEXISTING=1 ;
                fi
            else

                # Set the flag for copy the assets from the current half, if it applies
                COPYFROMEXISTING=1 ;
            fi
        else
            # Log
            log_warning "! Can't find file from delta package: file is not going to be updated" ;

            # Set the flag for copy the assets from the current half, if it applies
            COPYFROMEXISTING=1 ;
        fi

        # Check if, for some reasons, the asset should be copied
        # from the current half
        if [ $COPYFROMEXISTING -eq 1 ] && [ ! -z "${DB_HALF}" ]; then
            if [ ! -z "DB_HALF" ]; then

                diff "${FOLDER}/${FILE}" "${WORKOUTPUT}/${TARGETFILE}" >/dev/null 2>/dev/null ;
                if [ $? -eq 0 ]; then
                    # Log
                    log "+ No update available and no need to copy from current half (target file is already good)" ;
                else
                    # Log
                    log "+ No update available: copying from current half..." ;

                    # Copy file
                    cp -f "${FOLDER}/${FILE}" "${WORKOUTPUT}/${TARGETFILE}" ;

                    # Check result
                    if [ $? -ne 0 ]; then
                        log_error "# Error while copying from current half: cannot continue" ;
                        return -3 ;
                    fi

                    # Flush
                    sync ;

                    # Drop disk caches (for forcing the system to reload data from disk)
                    echo 3 > /proc/sys/vm/drop_caches ;

                    # Perform verification, if requested
                    if [ $SKIPVERIFICATION -ne 1 ]; then
                        TARGETDIGEST=$(sha256sum "${FOLDER}/${FILE}" 2>/dev/null | cut -d' ' -f1) ;
                        VERIFICATIONDIGEST=$(sha256sum "${WORKOUTPUT}/${TARGETFILE}" 2>/dev/null | cut -d' ' -f1) ;
                        if [ "$TARGETDIGEST" != "$VERIFICATIONDIGEST" ]; then
                            log_error "# Verification error while copying from current half: cannot continue" ;
                            return -4 ;
                        fi
                    fi
                fi
            fi
        fi
    fi
}

usage () {
    cat << EOF
Usage: ${0##*/} [-hxn] [-m <mode>] [-b <boot_folder> ] [ -d <data_folder> ] [ -o <output_folder> ] <DELTA_PACKAGE>

Applies the delta package provided at <DELTA_PACKAGE> to system.

<DELTA_PACKAGE> could an URL in http:// or https:// format (the package content
is going to be fetched from web server), in sftp:// or ssh:// format (the package
content is going to be fetched from SSH/SFTP server via SCP sequential protocol)
or can be a local system folder (file:// format or plain path).

If ssh:// or sftp:// is going to be used, then an enviroment variable named SSHPASS
can be used for expressing the full sshpass command to be used for passing
authentication credentials to SSH/SFTP server.

If the current booting scheme (detected or forced via "-m" option) is partitions-based then
the system expects to found the "inactive boot partition" to be mounted at position
"<boot_folder>-inactive", otherwise the script terminates with error.

-h  Displays this help and exit
-x  Use xdelta instead of xdelta3
-n  Do not verify delta (fast but unsafe)
-m  Forces the given boot scheme
    (<mode> can be "none", "files:a", "files:b" or "partitions")
-b  The folder containing boot assets (if not specified a guess is attempted based on platform)
-d  The folder containing non-boot assets (if not specified a guess is attempted based on platform)
-o  The output folder (if not specified, then the same <boot_folder> and <data_folder> are going
    to be used, based on asset type)

EOF
}

echo "Aesys(R) Gemini(TM) xdelta processor" ;
echo "Copyright (C) 2025 Aesys S.p.A." ;
echo "Version 1.0.0.0" ;
echo ;

# Set default argument vars
COMMANDLINE="$@" ;
COMMANDNAME="$0" ;
SCRIPTNAME=$(basename "$0") ;
XDELTA=0 ;
SKIPVERIFICATION=0 ;
FORCEDDUALBOOTSCHEME= ;
BOOTFOLDER= ;
DATAFOLDER= ;
OUTPUTFOLDER= ;

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
COMMANDLINE_OUTPUT="${HIST}/commandline.txt" ;
echo "$COMMANDNAME $COMMANDLINE" >> "$COMMANDLINE_OUTPUT" 2>/dev/null ;

OPTIND=1 ;
while getopts hxnm:b:d:o: opt; do
    case $opt in
        h)
            usage ;
            exit 0 ;
            ;;
        x)
            XDELTA=1 ;
            ;;
        n)
            SKIPVERIFICATION=1 ;
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

# Check command line parameters
if [ -z "$BOOTFOLDER" ]; then
    if [ "$PLATFORM" == "gemini" ]; then
        BOOTFOLDER="/boot" ;

        # On Gemini the boot folder needs to be mounted R/W
        mount -o remount,rw "${BOOTFOLDER}" >/dev/null 2>/dev/null ;
        if [ $? -ne 0 ]; then
            log_error "GEMINI: Cannot mount boot-folder as read-write" ;
            clean_up ;
            exit 2 ;
        fi
    fi
fi

if [ ! -d "$BOOTFOLDER" ]; then

    log_error "Invalid or unspecified boot folder" ;
    clean_up ;
    exit 2 ;
fi;

if [ -z "$DATAFOLDER" ]; then
    if [ "$PLATFORM" == "gemini" ]; then
        DATAFOLDER="/data/.sys" ;
    fi
fi

if [ ! -d "$DATAFOLDER" ]; then
    log_error "Invalid or unspecified data folder" ;
    clean_up ;
    exit 3 ;
fi;

# Check the availability of index.ini in DELTA_PACKAGE_FOLDER
PACKAGEFOLDER="$1" ;
PACKAGEINDEX=$(mktemp) ;
get_asset "$PACKAGEFOLDER/index.ini" > $PACKAGEINDEX ;
PACKAGEINDEXSIZE=$(wc -c "$PACKAGEINDEX" | cut -d' ' -f1) ;

if [ ! -f "$PACKAGEINDEX" ] || [ $PACKAGEINDEXSIZE -eq 0 ]; then
    log_error "Invalid or unspecified package folder" ;
    clean_up ;
    exit 4 ;
fi

# Prepare the output folder
if [ ! -z "$OUTPUTFOLDER" ] && [ "$OUTPUTFOLDER" != "$BOOTFOLDER" ] && [ "$OUTPUTFOLDER" != "$DATAFOLDER" ]; then
    rm -rf "$OUTPUTFOLDER" ;
    mkdir -p "$OUTPUTFOLDER" ;
fi

# Dump info
if [ -z "$PLATFORM" ]; then
    log "Platform: (not specified)" ;
else
    log "Platform: ${PLATFORM^^}" ;
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
        exit 5 ;
    fi
else
    KERNEL_CMDLINE=`cat /proc/cmdline` ;
    DB_CMDLINE_CURRENTHALF=`echo ${KERNEL_CMDLINE} | grep "db_active_half="` ;
    DB_CMDLINE_MODE=`echo ${KERNEL_CMDLINE} | grep "db_mode="` ;

    if [ ! -z "${DB_CMDLINE_CURRENTHALF}" ] && [ ! -z "${DB_CMDLINE_MODE}" ]; then
        DB_HALF=`echo $DB_CMDLINE_CURRENTHALF | sed -e 's/^.*db_active_half=//' -e 's/ .*$//'` ;
        DB_MODE=`echo $DB_CMDLINE_MODE | sed -e 's/^.*db_mode=//' -e 's/ .*$//'` ;
    fi
fi

# Dump detected booting scheme
BOOTFOLDEROTHER= ;
if [ -z "$DB_HALF" ]; then
    log "Booting scheme: SINGLE boot $DB_FORCED_ADDINFO" ;
elif [ "${DB_MODE}" == "partitions" ]; then
    log "Booting scheme: DUAL boot (partitions-based, current half: ${DB_HALF^^}) $DB_FORCED_ADDINFO" ;
    BOOTFOLDEROTHER="${BOOTFOLDER}-inactive" ;

    if [ ! -d ${BOOTFOLDEROTHER} ]; then
        log_error "Cannot access the inactive-half boot partition: cannot continue" ;
        clean_up ;
        exit 6;
    fi

    # On Gemini the boot folder needs to be mounted R/W
    if [ "$PLATFORM" == "gemini" ]; then
        mount -o remount,rw "${BOOTFOLDEROTHER}" >/dev/null 2>/dev/null ;
        if [ $? -ne 0 ]; then
            log_error "GEMINI: Cannot mount inactive boot folder as read-write" ;
            clean_up ;
            exit 7 ;
        fi
    fi
else
    log "Booting scheme: DUAL boot (files-based, current half: ${DB_HALF^^}) $DB_FORCED_ADDINFO" ;
fi
log

# Determine the list of files in boot folder to be updated
FILES=( $(ls -1p "${BOOTFOLDER}" | grep -v "/") ) ;
for f in ${FILES[@]}; do

    # Apply delta to current file, if any
    delta_file "${BOOTFOLDER}" "${f}" "${BOOTFOLDEROTHER}";

    # Check result
    if [ $? -ne 0 ]; then
        log_error "Error detected while processing boot files: cannot continue" ;
        clean_up ;
        exit 8;
    fi
done

# Determine the list of files in data folder to be updated
# (all .bin* files, for also handling .bin.a and .bin.b, except persist.bin)
FILES=( $(ls -1p "${DATAFOLDER}"/*.bin* | grep -v "/" | grep -v "persist.bin" ) ) ;
for f in ${FILES[@]}; do

    # Apply delta to current file, if any
    delta_file "${DATAFOLDER}" "${f}" ;

    # Check result
    if [ $? -ne 0 ]; then
        log_error "Error detected while processing data files: cannot continue" ;
        clean_up ;
        exit 9;
    fi
done

# Clean-up
clean_up ;
