#!/bin/bash
# ISP-A hacker
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

# allow anyone, including "debian" used by hacker, to write into web root
chmod 777 /var/www/html

# store EICAR as base64 and decode it in the machine, instead of storing it as a file that triggers the AV when cloning this repository
mkdir -p /home/debian/tp/ids/
echo "WDVPIVAlQEFQWzRcUFpYNTQoUF4pN0NDKTd9JEVJQ0FSLVNUQU5EQVJELUFOVElWSVJVUy1URVNULUZJTEUhJEgrSCo=" | base64 -d > /home/debian/tp/ids/eicar.txt

chown -R debian:debian /home/debian

# Disable DHCP and do DNS config
#sed -i "s/.*dhcp.*//" /etc/network/interfaces
#echo -e "domain internet.virt\nsearch internet.virt\nnameserver 10.0.0.1" > /etc/resolv.conf

# https://help.gnome.org/users/epiphany/stable/cert.html.en
# p11-kit : trust anchor /home/user/Downloads/certificate.crt
