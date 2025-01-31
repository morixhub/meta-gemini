#!/bin/bash
CFG=/etc/ifplugd/ifplugd.conf

IFPLUGD=/usr/sbin/ifplugd
test -x $IFPLUGD || exit 0

if [ `id -u` != "0" ] && [ "$1" = "start" -o "$1" = "stop" ] ; then
  echo "You must be root to start, stop or restart ifplugd."
  exit 1
fi

[ -f $CFG ] && . $CFG

VERB="$1"
shift

[ "x$*" != "x" ] && INTERFACES="$*"

[ "x$INTERFACES" = "xauto" ] && INTERFACES="`cat /proc/net/dev | awk '{ print $1 }' | egrep '^(eth|wlan)' | cut -d: -f1`"

case "$VERB" in
    start)
        echo -n "Starting Network Interface Plugging Daemon:"
        for IF in $INTERFACES ; do
            A="`eval echo \$\{ARGS_${IF}\}`"
            [ -z "$A" ] && A="$ARGS"
            echo "IF=" $IF "A=" $A
            $IFPLUGD -i $IF $A
            echo -n " $IF"
        done
        echo "."
        ;;
    stop)
        echo -n "Stopping Network Interface Plugging Daemon:"
        for IF in $INTERFACES ; do
            $IFPLUGD -k -i $IF
            echo -n " $IF"
        done
        echo "."
        ;;
    status)
        for IF in $INTERFACES ; do
            $IFPLUGD -c -i $IF
        done
        ;;
    suspend)
        echo -n "Suspending Network Interface Plugging Daemon:"
        for IF in $INTERFACES ; do
            $IFPLUGD -S -i $IF
            echo -n " $IF"
        done
        echo "."
        ;;
    resume)
        echo -n "Resuming Network Interface Plugging Daemon:"
        for IF in $INTERFACES ; do
            $IFPLUGD -R -i $IF
            echo -n " $IF"
        done
        echo "."
        ;;
    force-reload|restart)
        $0 stop $INTERFACES
        sleep 3
        $0 start $INTERFACES
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|force-reload|status|suspend|resume}"
        exit 1
esac

exit 0
