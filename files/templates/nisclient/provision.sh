#!/bin/bash
# nisclient template
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

# DEBIAN_FRONTEND=noninteractive apt-get install -y thunderbird

# NIS client
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -d -y nis
mv /etc/resolv.conf /etc/resolv.conf.bak
DEBIAN_FRONTEND=noninteractive apt-get install -y nis
mv /etc/resolv.conf.bak /etc/resolv.conf
echo "$domain" > /etc/defaultdomain
echo "ypserver $nisserver" >> /etc/yp.conf
sed -i -e 's/compat/compat nis/' /etc/nsswitch.conf
