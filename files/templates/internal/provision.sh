#!/bin/bash
# Internal template
set -e
if [ -z `hostname | grep lxc-infra` ] ; then exit 1; fi

# systemctl set-default graphical.target

# DEBIAN_FRONTEND=noninteractive apt-get install -y thunderbird

# Disable DHCP and do DNS config
sed -i "s/.*dhcp.*//" /etc/network/interfaces
echo -e "domain $domain\nsearch $domain\nnameserver $ns" > /etc/resolv.conf
