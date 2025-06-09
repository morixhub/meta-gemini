#!/bin/bash

# Constants
OVERLAYENFORCED="/initram/overlayroot.enforced"

# General function
main_help () {
    echo "USAGE" ;
    echo "   ./overlayroot-commit.sh {<filename>|<dirname>} [<options>]" ;
    echo ;
    echo "Where <filename> (or <dirname>) can be either an absolute or relative path to an" ;
    echo "existing file (or directory); if <filename> (or <dirname>) does not exist, then" ;
    echo "the commit of a file removal is assumed." ;
    echo ;
    echo "<options> can be one of the following:" ;
    echo ;
    echo "   -v, --verbose" ;
    echo "         Toggles verborse mode" ;
    echo ;
    echo "      -h, --help" ;
    echo "         Show this help screen" ;
    echo ;
    echo "Exits with 0 if successfull; otherwise an error code is used as status code," ;
    echo "following the given table:" ;
    echo "        0: success" ;
    echo "       -1: invalid command line or help requested" ;
    echo "       -2: overlay root is not active: cannot commit" ;
    echo "       -3: cannot determine persisted root or persisted root not available" ;
    echo "  (other): error code returned by system's cp (if a file write is going to be" ;
    echo "           commited) or system's rm (if a file removal is going to be commited)" ;
    echo ;
}

# Initialize vars
POSITIONAL_ARGS=()
VERBOSE=

# Use -gt 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
while [[ $# -ge 1 ]]
do
    key="$1" ;

    case $key in
        -h|--help)
            main_help ;
            exit -1 ;
            ;;
        -v|--verbose)
            VERBOSE=$key ;
            ;;
        -*|--*)
            main_help ;
            exit -1 ;
            ;;
        *)
            POSITIONAL_ARGS+=($1) ;
            ;;
    esac
    shift; # past argument
done;

# Restore positional args
SOURCE="${POSITIONAL_ARGS[@]}"

# Check arguments
if [ -z "$SOURCE" ]; then
    main_help ;
    exit -1 ;
fi

# Check if overlay is enforced
if [ ! -f "$OVERLAYENFORCED" ]; then
    echo "Overlayroot is not active: cannot commit" ;
    exit -2 ;
fi

# Check persist root availability
PERSISTEDROOT=$(cat "$OVERLAYENFORCED")
if [ -z "$PERSISTEDROOT" ] || [ ! -d "$PERSISTEDROOT" ]; then
    echo "Cannot determine persisted root or persisted root not available" ;
    exit -3 ;
fi

# Determine full path to target file
TARGETFILE=""
if [[ "$SOURCE" = /* ]]; then
    TARGETFILE="$PERSISTEDROOT$SOURCE" ;
else
    TARGETFILE="$PERSISTEDROOT$PWD/$SOURCE" ;
fi

# Process file
RES=0
if [ -d "$SOURCE" ]; then
    if [ ! -z "$VERBOSE" ]; then
        echo "Syncing folder $SOURCE to $TARGETFILE..." ;
    fi
    mkdir $VERBOSE -p $(dirname "$TARGETFILE") ;
    rsync $VERBOSE -a "$SOURCE/" "$TARGETFILE/" --delete ;
    RES=$?
elif [ -e "$SOURCE" ]; then
    if [ ! -z "$VERBOSE" ]; then
        echo "Syncing file $SOURCE to $TARGETFILE..." ;
    fi
    mkdir $VERBOSE -p $(dirname "$TARGETFILE") ;
    cp $VERBOSE -arf "$SOURCE" "$TARGETFILE" ;
    RES=$?
else
    if [ ! -z "$VERBOSE" ]; then
        echo "Removing $TARGETFILE..." ;
    fi
    rm $VERBOSE -rf "$TARGETFILE" ;
    RES=$?
fi

# Ensure file-system syncing
sync;

# Return result
exit $RES