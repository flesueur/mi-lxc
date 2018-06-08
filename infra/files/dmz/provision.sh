#!/bin/bash
# DMZ

# DEBIAN_FRONTEND=noninteractive apt-get install -y thunderbird

DEBIAN_FRONTEND=noninteractive apt-get install -y unbound postfix dovecot-imapd proftpd apt-transport-https wget

cp /mnt/lxc/dmz/dns.conf /etc/unbound/unbound.conf.d/

sed -i -e 's/ssl = no/ssl = yes/' /etc/dovecot/conf.d/10-ssl.conf
echo "ssl_cert = </etc/ssl/certs/ssl-cert-snakeoil.pem" >> /etc/dovecot/conf.d/10-ssl.conf
echo "ssl_key = </etc/ssl/private/ssl-cert-snakeoil.key" >> /etc/dovecot/conf.d/10-ssl.conf
echo "disable_plaintext_auth = no" >> /etc/dovecot/conf.d/10-auth.conf

sed -i -e 's/mydestination = /mydestination = target.virt, /' /etc/postfix/main.cf
sed -i -e 's/mynetworks = /mynetworks = 192.168.0.0\/16 /' /etc/postfix/main.cf


useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 commercial` commercial || true
addgroup commercial mail
useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 @password` insa || true

cp /mnt/lxc/dmz/ossec.list /etc/apt/sources.list.d/
#wget -q -O /tmp/key https://www.atomicorp.com/RPM-GPG-KEY.art.txt
#apt-key add /tmp/key
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-unauthenticated ossec-hids-server

# Disable DHCP and do DNS config
sed -i "s/.*dhcp.*//" /etc/network/interfaces
echo -e "domain target.virt\nsearch target.virt\nnameserver 192.168.1.2" > /etc/resolv.conf
