#!/bin/bash
# Commercial

# systemctl set-default graphical.target

# DEBIAN_FRONTEND=noninteractive apt-get install -y thunderbird

tar zxvf /mnt/lxc/hacker/thunderbird.tar.gz -C /home/debian/

#cp -ar /mnt/lxc/commercial/homedir/* /home/debian/
#ln -sf /home/debian/background.jpg /usr/share/images/desktop-base/default
chown -R debian:debian /home/debian

# remove nmap binary
rm /usr/bin/nmap

# Disable DHCP and do DNS config
sed -i "s/.*dhcp.*//" /etc/network/interfaces
echo -e "domain target.virt\nsearch target.virt\nnameserver 192.168.1.2" > /etc/resolv.conf
