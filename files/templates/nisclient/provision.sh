#!/bin/bash
# Firewall template

if [ -z `hostname | grep lxc-infra` ] ; then exit 1; fi

# DEBIAN_FRONTEND=noninteractive apt-get install -y thunderbird

# NIS client
DEBIAN_FRONTEND=noninteractive apt-get install -d -y nis
mv /etc/resolv.conf /etc/resolv.conf.bak
DEBIAN_FRONTEND=noninteractive apt-get install -y nis
mv /etc/resolv.conf.bak /etc/resolv.conf
echo "$domain" > /etc/defaultdomain
echo "ypserver $nisserver" >> /etc/yp.conf
sed -i -e 's/compat/compat nis/' /etc/nsswitch.conf
