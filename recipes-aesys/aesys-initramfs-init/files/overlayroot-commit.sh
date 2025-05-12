#!/bin/bash

# Constants
OVERLAYENFORCED="/initram/overlayroot.enforced"

# General function
main_help () {
    echo "USAGE" ;
    echo "   ./overlayroot-commit.sh <filename> [<options>]" ;
    echo ;
    echo "Where <filename> can be either an absolute or relative path to an existing file;" ;
    echo "if <filename> does not exist, then the commit of a file removal is assumed." ;
    echo ;
    echo "<options> can be one of the following:" ;
    echo ;
    echo "   -h, --help" ;
    echo "      Show this help screen" ;
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

# Collect positional args
POSITIONAL_ARGS=()

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
            exit -1;
            ;;
        -*|--*)
            main_help ;
            exit -1;
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
if [ -e "$SOURCE" ]; then
    mkdir -p $(dirname "$TARGETFILE") ;
    cp -arf "$SOURCE" "$TARGETFILE" ;
else
    rm -rf "$TARGETFILE" ;
fi
