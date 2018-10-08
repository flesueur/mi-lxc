#!/bin/bash
# Filer

if [ -z `hostname | grep lxc-infra` ] ; then exit 1; fi

#DEBIAN_FRONTEND=noninteractive apt-get install -y libapache2-mod-php php-sqlite3 sqlite3

#cp /mnt/lxc/filer/index.php.sqlite /var/www/html/index.php
#mv /var/www/html/index.html /var/www/html/index.old.html
#sqlite3 /var/www/html/appli.db < /mnt/lxc/filer/db.sqlite

# BO part
#echo -e '#!/bin/bash\n/root/launcher.sh 2>/dev/null &\n/root/launcher12345.sh 2>/dev/null &\nexit 0' > /etc/rc.local
#chmod +x /etc/rc.local
#cp -ar /mnt/lxc/filer/root/* /root/
#dpkg --add-architecture i386
#apt-get update
#apt-get install -y libc6:i386

# Disable DHCP and do DNS config
#sed -i "s/.*dhcp.*//" /etc/network/interfaces
#echo -e "domain target.virt\nsearch target.virt\nnameserver 192.168.1.2" > /etc/resolv.conf

# useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 commercial` commercial || true
#useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 devdev` dev || true

mkdir -p /home/commercial/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDmAxoKkJqasCB83L8/aD9D7583NK1HoIuJJv4Gq6r6HzaIkgcbaUWzivuyPXEiY6eaVAJHLr4IUMOfGr2y1ap5HlXNJ+Zk9jfwcXRDwWnnRJProkIfluotPjGA5DZrZMyK0ip/tPJjFFzUM+JiqSzTSL61BBd0TH3IBqLeuFipDNcQzNdrgB8IlvgxlaZ2b9q5OlJE9r83OCZh8977E3+FHPJTqj98ZfG8k1EYDCAPlvQslkfZJ4Q4kRpljc3E8fbtoX4bViNQiIHodYOieiiStwhmhqGj7X9J31CvvDODCM4R4ABG32tCFFyJslYLtLyGwUM1fmbMsmTDl3EYDw4D debian@lxc-infra-commercial" > /home/commercial/.ssh/authorized_keys
chown -R 1001:1001 /home/commercial
mkdir -p /home/dev/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDa4dl8EK4raMwsjuesjKrZlMRuSOAL2JuiOdidQ3ZnJsKi2csLD1ajuHixLJCpNkdqwgovdK6h/PJWCRMp/5LkJa+dq47xYkXNqQnAOTG+HbwlPxspJz7dPq7nb0hnAFDg1UhwqKAwG/1DPI3sLlXmL6M4+VclKCT69LC1mkCDChQUK7uuCZC3cdERxbgXTiUs4o9ITLlOlPXTRPyoE+hooFcFgiDO/S4OtSVBzyXZRQo1OZriiWhJugoGDOWJdDGjNfNb2lXD0ZGJ8yrQYk64DuMwWflA3g/ijEKgq9/6qUCbIruQI7zkoq64uMgz4VJzJMUyxe7vFoA917Ah5rVT root@lxc-infra-commercial" > /home/dev/.ssh/authorized_keys
chown -R 1002:1001 /home/dev
mkdir -p /home/admin/.ssh
chown -R 1003:1001 /home/admin

mkdir /home/shared
chgrp 1001 /home/shared
chmod 770 /home/shared

cp -ar /mnt/lxc/filer/shared/ /home/
chown -R 1002  /home/shared/dev
chmod 760 /home/shared/dev/deploy.sh
