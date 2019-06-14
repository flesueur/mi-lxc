#!/bin/bash
# Firewall template
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

exit 1

# DEBIAN_FRONTEND=noninteractive apt-get install -y thunderbird

# Disable DHCP and do DNS config
#sed -i "s/.*dhcp.*//" /etc/network/interfaces
#echo -e "domain internet.virt\nsearch internet.virt\nnameserver 10.0.0.1" > /etc/resolv.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
