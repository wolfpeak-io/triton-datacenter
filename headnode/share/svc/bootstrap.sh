#!/bin/sh

# Wolfpeak - Boot time bootstrap

# this is essentially an init script which calls the deploy.sh script
# see the deploy.sh script for information on the general setup tasks
# which are performed upon booting the triton headnode
 
set -o xtrace
 
. /lib/svc/share/smf_include.sh
 
cd /
PATH=/usr/sbin:/usr/bin:/opt/custom/bin:/opt/custom/sbin; export PATH
 
case "$1" in
'start')
    /opt/custom/share/svc/deploy.sh
 
    ;;
 
'stop')
    ;;
 
*)
    printf "Usage: $0 { start | stop }\n"
    exit $SMF_EXIT_ERR_FATAL
    ;;
esac
exit $SMF_EXIT_OK
