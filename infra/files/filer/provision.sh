#!/bin/bash
# Filer

if [ -z `hostname | grep lxc-infra` ] ; then exit 1; fi

# DEBIAN_FRONTEND=noninteractive apt-get install -y thunderbird

cp /mnt/lxc/filer/index.php /var/www/html/
mv /var/www/html/index.html /var/www/html/index.old.html

# Disable DHCP and do DNS config
sed -i "s/.*dhcp.*//" /etc/network/interfaces
echo -e "domain target.virt\nsearch target.virt\nnameserver 192.168.1.2" > /etc/resolv.conf
