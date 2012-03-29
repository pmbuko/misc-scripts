#!/bin/bash
#
# This script makes it easy to change a workstation's ip address. You must
# supply the new ip address as the only argument when calling the script. The                                                                
# gateway change is handled automatically based on the supplied ip address.

if [[ $# != 1 ]]; then echo "You must supply a single IP address." && exit 1; fi

newip="$1"
config="/etc/sysconfig/network-scripts/ifcfg-eth0"
oldip=$(awk -F= '/IPADDR/{gsub("\"","");print $2}' $config)
newgw=$(echo $newip | awk '{sub(".[0-9]+$",".1"); print}')

echo ""
echo -n "The old address $(tput bold)$(tput setaf 1)$oldip$(tput sgr0) "

sed -i.orig -e"s/^IPADDR=.*$/IPADDR=$newip/" -e"s/^GATEWAY=.*$/GATEWAY=$newgw/" $config

echo "has been changed to $(tput bold)$(tput setaf 2)$newip$(tput sgr0)."
echo ""
echo "Next steps:"
echo ""
echo "  1. Type $(tput bold)$(tput setaf 4)service network start$(tput sgr0) to bring up the network interface."
echo "  2. Type $(tput bold)$(tput setaf 4)ping -c 3 $newgw$(tput sgr0) to verify that the network is now functioning."
echo "  3. Type $(tput bold)$(tput setaf 4)exit$(tput sgr0) to boot the computer normally."
echo "  4. Inform the linux team of the computer's new ip address."
echo ""
