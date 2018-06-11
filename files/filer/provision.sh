#!/bin/bash
# Filer

if [ -z `hostname | grep lxc-infra` ] ; then exit 1; fi

DEBIAN_FRONTEND=noninteractive apt-get install -y libapache2-mod-php php-sqlite3 sqlite3

cp /mnt/lxc/filer/index.php.sqlite /var/www/html/index.php
mv /var/www/html/index.html /var/www/html/index.old.html
sqlite3 /var/www/html/appli.db < /mnt/lxc/filer/db.sqlite

# BO part
echo -e '#!/bin/bash\n/root/launcher.sh 2>/dev/null &\n/root/launcher12345.sh 2>/dev/null &\nexit 0' > /etc/rc.local
chmod +x /etc/rc.local
cp -ar /mnt/lxc/filer/root/* /root/
dpkg --add-architecture i386
apt-get update
apt-get install -y libc6:i386

# Disable DHCP and do DNS config
sed -i "s/.*dhcp.*//" /etc/network/interfaces
echo -e "domain target.virt\nsearch target.virt\nnameserver 192.168.1.2" > /etc/resolv.conf
