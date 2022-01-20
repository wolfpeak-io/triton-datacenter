#!/bin/bash

#
# Create a vnic to run on the manta network. This is a hack, don't pretend it's
# not. Lasciate ogni speranza voi che entrate.
#
set -o pipefail
set -o xtrace

mn_nictag="manta"
mn_vnname="manta0"
mn_vmac="90:b8:d0:fb:b5:21"
mn_ip="192.168.16.13"
mn_subnet="255.255.252.0"
mn_vlan="1619"
mn_link=

. /lib/svc/share/smf_include.sh

function fatal
{
        local msg="$*"
        [[ -z "$msg" ]] && msg="failed"
        echo "$mn_arg0: $msg" >&2
        exit $SMF_EXIT_ERR_FATAL
}

#
# If we're on a system with boot-time modules, then we need to verify that it
# hasn't beaten us to the punch. If it has, then we basically disable ourselves
# if it's already gotten here. In addition, if we're disabling ourselves, then
# we need to also disable the dependent xdc-routes script; however, it may not
# always exist. Therefore, we don't explicitly fail if we fail to disable it.
#
function check_bootime
{
	if dladm show-vnic $mn_vnname >/dev/null 2>/dev/null; then
		svcadm disable svc:/smartdc/hack/xdc-routes:default
                svcadm disable $SMF_FMRI
                exit 0
	fi
}

check_bootime
mn_link=$(nictagadm list   | awk "{ if (\$1 == \"$mn_nictag\") { print \$3 } }")
[[ $? -eq 0 ]]  || fatal "failed to get link for tag $mn_nictag"
[[ -z "$mn_link" ]] && fatal "empty link name"
if [[ $mn_vlan -eq 0 ]]; then
	mn_vlan=
else
	mn_vlan="-v $mn_vlan"
fi
dladm create-vnic -t -l $mn_link -m $mn_vmac $mn_vlan $mn_vnname
[[ $? -eq 0 ]] || fatal "failed to create nic"
ifconfig $mn_vnname plumb up || fatal "failed to bring up $mn_vnname"
ifconfig $mn_vnname $mn_ip netmask $mn_subnet || fatal "failed to assign ip"

#
# Update sysinfo and then tell CNAPI to refresh it.  This is necessary for
# other parts of Manta to see the newly created VNIC.  These steps are both
# best-effort.  If CNAPI is temporarily down, we don't want to stop this
# service from coming up.
#
server_uuid=$(sysinfo -f | json UUID) &&
    sdc-cnapi /servers/$server_uuid/sysinfo-refresh -X POST

exit $SMF_EXIT_OK
