#!/bin/bash
# Firewall template

if [ -z `hostname | grep lxc-infra` ] ; then exit 1; fi

# DEBIAN_FRONTEND=noninteractive apt-get install -y thunderbird

# Disable DHCP and do DNS config
#sed -i "s/.*dhcp.*//" /etc/network/interfaces
#echo -e "domain internet.virt\nsearch internet.virt\nnameserver 10.0.0.1" > /etc/resolv.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
