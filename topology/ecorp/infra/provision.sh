#!/bin/bash
# Ecorp infra
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

DEBIAN_FRONTEND=noninteractive apt-get install -y certbot python3-certbot-apache

# Hacker's mail account hacker@isp-a.milxc
useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 admin` admin || true
adduser admin mail
#mkdir /home/hacker/mail
#touch /home/hacker/mail/Drafts /home/hacker/mail/Queue /home/hacker/mail/Sent /home/hacker/mail/Trash

DEB_VERSION=`cat /etc/debian_version | cut -d'.' -f1`
if [ $DEB_VERSION -eq "11" ] # DEB 11 aka Bullseye
then
	# disable systemd-resolved which conflicts with nsd
	echo "DNSStubListener=no" >> /etc/systemd/resolved.conf
	systemctl stop systemd-resolved
fi

# manage isp-a.milxc zone
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y unbound
cp dns.conf /etc/unbound/unbound.conf.d/

cp index.html /var/www/html/
ln -s /var/www/html/index.html /var/www/html/doku.php
a2enmod headers
echo "RequestHeader unset If-Modified-Since" >> /etc/apache2/apache2.conf

# preconfig TLS and certbot
a2enmod ssl
a2ensite default-ssl.conf
echo -e "
email=admin@target.milxc
agree-tos=1
no-verify-ssl=1
" >> /etc/letsencrypt/cli.ini
