#!/bin/bash
# Hacker
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

# systemctl set-default graphical.target

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y python3
DEBIAN_FRONTEND=noninteractive apt-get install -y python3-requests

cp -ar homedir/* /home/debian/
ln -sf /home/debian/background.jpg /usr/share/images/desktop-base/default
chown -R debian:debian /home/debian

# allow anyone, including "debian" used by hacker, to write into web root
chown 777 /var/www/html

# Disable DHCP and do DNS config
#sed -i "s/.*dhcp.*//" /etc/network/interfaces
#echo -e "domain internet.virt\nsearch internet.virt\nnameserver 10.0.0.1" > /etc/resolv.conf

# https://help.gnome.org/users/epiphany/stable/cert.html.en
# p11-kit : trust anchor /home/user/Downloads/certificate.crt
