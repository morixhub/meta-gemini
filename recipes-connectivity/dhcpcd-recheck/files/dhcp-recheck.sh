#!/bin/bash

DHCPCD_CONF=/etc/dhcpcd.conf
NIC=${1}

function isFallback() {
	# exit code 0 = no fallback, 1 = fallback
	fallbackFile="/tmp/static_"$NIC

	if [ -f $fallbackFile ]; then
		echo "1";
	else
		echo "0";
	fi
}

function isNotConfigured() {
	# exit code 0 = configured, 1 = not configured
	notConfigured=$(ip addr show dev ${NIC} | grep "inet ")

	if [ -z "$notConfigured" ]; then
			echo "1";
	else
			echo "0";
	fi
}

function isInterfaceDenied() {
	# exit code 0 = no fallback, 1 = fallback
	local denyInterfaceStr="denyinterfaces ${NIC}"
	local isDeniedStr=$(cat ${DHCPCD_CONF} | grep "${denyInterfaceStr}")
	if [ -z "$isDeniedStr" ]; then
		echo "0";
	else
		echo "1";
	fi
}

function reach_dhcp_server_on_interface() {
	local interface=${NIC}
	# nmap command to find a DHCP server on an interface
	local nmap_command="nmap --script broadcast-dhcp-discover -e ${interface}"

	# exit code 0 = router, 1 = no router
	local response=$(${nmap_command} 2>/dev/null | grep Response) 
	if [ -z "$response" ]; then
		echo "0";
	else
		echo "1";
	fi
}

function reset_ip() {
	# Flush interface $NIC
	ip addr flush dev $NIC
	# Tell dhcpcd to rebind $NIC
	dhcpcd -n $NIC
}

fallback=$(isFallback)
isDenied=$(isInterfaceDenied)
isNotCfg=$(isNotConfigured)

if [ "$fallback" -eq "0" ] || [ "$isNotCfg" -eq "1" ] || [ "$isDenied" -eq "1" ];
then
        echo "Nothing to do on $NIC: fallback is not active, device is not configured or device is denied"
        exit 0;
fi


if [ "$isNotCfg" -eq "1" ];
then
    echo "$NIC not configured but fallback active, going to restart interface"
        ifdown $NIC
        ifup $NIC
    exit 0;
fi

# Check for a DHCP server; if not found then exit
echo "Fallback active on $NIC... checking for DHCP server";

isDhcpServerPresent=$(reach_dhcp_server_on_interface)
if [ "$isDhcpServerPresent" -eq "0" ];
then
        echo "DHCP server not found for $NIC" ;
        exit 0;
fi

# Remove the static
rm -rf "/tmp/static_"$NIC
echo "DHCP server found for $NIC: resetting IP..."
reset_ip

