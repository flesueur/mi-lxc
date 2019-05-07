#!/bin/bash
# intranet
set -e
if [ -z `hostname | grep lxc-infra` ] ; then exit 1; fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y libapache2-mod-php php-sqlite3 sqlite3

cp /mnt/lxc/intranet/index.php.sqlite /var/www/html/index.php
mv /var/www/html/index.html /var/www/html/index.old.html
sqlite3 /var/www/html/appli.db < /mnt/lxc/intranet/db.sqlite

# BO part
echo -e '#!/bin/bash\n/root/launcher.sh 2>/dev/null &\n/root/launcher12345.sh 2>/dev/null &\nexit 0' > /etc/rc.local
chmod +x /etc/rc.local
cp -ar /mnt/lxc/intranet/root/* /root/
dpkg --add-architecture i386
apt-get update
apt-get install -y libc6:i386

cp /mnt/lxc/intranet/clients.txt /var/www/html/
cp /mnt/lxc/intranet/compta.txt /var/www/html/
chmod 666 /var/www/html/clients.txt
chmod 666 /var/www/html/compta.txt

mkdir -p /home/dev/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDa4dl8EK4raMwsjuesjKrZlMRuSOAL2JuiOdidQ3ZnJsKi2csLD1ajuHixLJCpNkdqwgovdK6h/PJWCRMp/5LkJa+dq47xYkXNqQnAOTG+HbwlPxspJz7dPq7nb0hnAFDg1UhwqKAwG/1DPI3sLlXmL6M4+VclKCT69LC1mkCDChQUK7uuCZC3cdERxbgXTiUs4o9ITLlOlPXTRPyoE+hooFcFgiDO/S4OtSVBzyXZRQo1OZriiWhJugoGDOWJdDGjNfNb2lXD0ZGJ8yrQYk64DuMwWflA3g/ijEKgq9/6qUCbIruQI7zkoq64uMgz4VJzJMUyxe7vFoA917Ah5rVT root@lxc-infra-commercial" > /home/dev/.ssh/authorized_keys
chown -R 1002:1001 /home/dev # should be 1001 (employees)

#cp /mnt/lxc/prod/index.php /var/www/html/index.php
#mv /var/www/html/index.html /var/www/html/index.old.html
