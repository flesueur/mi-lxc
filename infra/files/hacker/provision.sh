#!/bin/bash
# Hacker

# systemctl set-default graphical.target

# DEBIAN_FRONTEND=noninteractive apt-get install -y thunderbird

tar zxvf /mnt/lxc/hacker/thunderbird.tar.gz -C /home/debian/

cp -ar /mnt/lxc/hacker/homedir/* /home/debian/
ln -sf /home/debian/background.jpg /usr/share/images/desktop-base/default
chown -R debian:debian /home/debian

# Disable DHCP and do DNS config
sed -i "s/.*dhcp.*//" /etc/network/interfaces
echo -e "domain internet.virt\nsearch internet.virt\nnameserver 10.0.0.1" > /etc/resolv.conf
