#!/bin/bash
# Filer

# DEBIAN_FRONTEND=noninteractive apt-get install -y thunderbird

# Disable DHCP and do DNS config
sed -i "s/.*dhcp.*//" /etc/network/interfaces
echo -e "domain target.virt\nsearch target.virt\nnameserver 192.168.1.2" > /etc/resolv.conf
