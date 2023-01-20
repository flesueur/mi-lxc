#!/bin/bash
# Target DMZ
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

sed -i -e 's/127.0.1.1.*$/127.0.1.1\tlxc-infra-dmz/' /etc/hosts

# disable systemd-resolved which conflicts with nsd
echo "DNSStubListener=no" >> /etc/systemd/resolved.conf
systemctl stop systemd-resolved

apt-get update
DEB_VERSION=`cat /etc/debian_version | cut -d'.' -f1`
if [ $DEB_VERSION -eq "11" ] # DEB 11 aka Bullseye
then
  DEBIAN_FRONTEND=noninteractive apt-get install -y dokuwiki certbot python3-certbot-apache nsd dovecot-imapd proftpd apt-transport-https wget prelude-utils libprelude-dev build-essential php-mbstring php libevent-dev libpcre2-dev zlib1g-dev libssl-dev libsystemd-dev
elif [ $DEB_VERSION -eq "10" ] # DEB 10 aka Buster
then
  DEBIAN_FRONTEND=noninteractive apt-get install -y dokuwiki certbot python3-certbot-apache nsd dovecot-imapd proftpd apt-transport-https wget prelude-utils libprelude-dev build-essential php7.3-mbstring php7.3 libevent-dev libpcre2-dev zlib1g-dev libssl-dev
elif [ $DEB_VERSION -eq "9" ] # DEB 9 aka stretch
then
  DEBIAN_FRONTEND=noninteractive apt-get install -y nsd dovecot-imapd proftpd apt-transport-https wget libprelude2 libprelude-dev build-essential  php7.0-mbstring php7.0
else
  echo "Unsupported Debian version"
  exit 1
fi

# Reverse DNS server

mkdir -p /etc/nsd
echo -e "zone:
	name: \"80.100.in-addr.arpa.\"
	zonefile: \"80.100.zone\"
" >> /etc/nsd/nsd.conf

cp dns-reverse.conf /etc/nsd/80.100.zone

# allow to create homedirs when ldap authentication succeeds in IMAP - pam_mkhomedir does not work with imap auth (no pam-session in imap), other solution would be to manually create needed directories
echo -e '#!/bin/sh\nchmod 777 /home\nchmod o+t /home\nexit 0' > /etc/rc.local
chmod +x /etc/rc.local


# Install de dokuwiki
# rm -f /var/www/html/index.html
# wget https://github.com/splitbrain/dokuwiki/archive/release_stable_2018-04-22b.tar.gz -O /tmp/dokuwiki.tar.gz
# tar zxf /tmp/dokuwiki.tar.gz -C /var/www/html --strip 1
# echo "sh      application/x-sh" >> /var/www/html/conf/mime.conf
# PASS=`mkpasswd -5 superman`
# echo "admin:$PASS:admin:admin@target.milxc:admin,user" >> /var/www/html/conf/users.auth.php
# echo "* @ALL  1" > /var/www/html/conf/acl.auth.php
# echo "* @user  8" >> /var/www/html/conf/acl.auth.php
# cp doku/local.php /var/www/html/conf/
# cp doku/start.txt /var/www/html/data/pages/
# chown -R www-data /var/www/html/*

echo "sh      application/x-sh" >> /etc/dokuwiki/mime.conf
#PASS=`mkpasswd -5 superman`
PASS=`echo -n superman | sha1sum | awk '{print $1}'`
echo "admin:$PASS:admin:admin@target.milxc:admin,user" > /etc/dokuwiki/users.auth.php
cp doku/local.php /etc/dokuwiki/
cp doku/start.txt /var/lib/dokuwiki/data/pages/
chown www-data /var/lib/dokuwiki/data/pages/start.txt
sed -i -e 's/Allow from .*/Allow from All/' /etc/apache2/conf-available/dokuwiki.conf
sed -i -e 's/DocumentRoot .*/DocumentRoot \/usr\/share\/dokuwiki/' /etc/apache2/sites-available/000-default.conf
sed -i -e 's/DocumentRoot .*/DocumentRoot \/usr\/share\/dokuwiki/' /etc/apache2/sites-available/default-ssl.conf
a2enmod headers
echo "RequestHeader unset If-Modified-Since" >> /etc/apache2/apache2.conf
# des chown ?
# Points d'entrée : le BF, le leak de mdp, une RCE pour webshell ajouté manuellement
# de là : rebond vers le commercial, ou direct depuis DMZ. Si webshell, il faut le mdp du commercial : récup du fichier doku users.auth.php
# le pass est stocké en MD5 hashé : le brute-forcer en local, c'est rapide


# Install de OSSEC avec support prelude
cd /tmp
# wget https://github.com/ossec/ossec-hids/archive/3.6.0.tar.gz
wget https://github.com/ossec/ossec-hids/archive/356562583ba7242f46c4c8adb1350f5f9509b759.zip -O ossec.zip
#tar zxvf 3.6.0.tar.gz
unzip ossec.zip
cd ossec-hids-* #3.6.0
cp $DIR/preloaded-vars.conf etc/
USE_PRELUDE=yes ./install.sh

sed -i -e 's/<rule id="31151" level="10" frequency="12" timeframe="90">/<rule id="31151" level="5" frequency="12" timeframe="90">/' /var/ossec/rules/web_rules.xml # deactivate active-response/firewall block when multiple http forbidden
sed -i -e 's/\/var\/www\/logs\/access_log/\/var\/log\/apache2\/access.log/' /var/ossec/etc/ossec.conf
sed -i -e 's/\/var\/www\/logs\/error_log/\/var\/log\/apache2\/error.log/' /var/ossec/etc/ossec.conf
sed -i -e 's/<\/global>/<prelude_output>no<\/prelude_output>\n<prelude_profile>OSSEC-DMZ<\/prelude_profile>\n<prelude_log_level>0<\/prelude_log_level>\n<\/global>/' /var/ossec/etc/ossec.conf
sed -i -e 's/<frequency>79200<\/frequency>/<frequency>60<\/frequency>/' /var/ossec/etc/ossec.conf
sed -i -e 's/<directories check_all="yes">/<directories check_all="yes" realtime="no">/' /var/ossec/etc/ossec.conf
sed -i -e 's/server-addr = 127.0.0.1/server-addr = 100.80.0.1/' /etc/prelude/default/client.conf

# OSSEC timing : https://github.com/ossec/ossec-hids/blob/da6814e6e7320abc878feecd44ed4f3901eb343f/src/syscheckd/run_check.c#L266
# https://github.com/ossec/ossec-hids/blob/da6814e6e7320abc878feecd44ed4f3901eb343f/src/syscheckd/run_check.c#L78
# https://github.com/ossec/ossec-hids/blob/da6814e6e7320abc878feecd44ed4f3901eb343f/src/syscheckd/run_check.c#L122-L124
# https://github.com/ossec/ossec-hids/blob/da6814e6e7320abc878feecd44ed4f3901eb343f/src/syscheckd/syscheck.c#L54

# create prelude-admin spool directory
mkdir /var/spool/prelude

#cp /mnt/lxc/dmz/ossec.list /etc/apt/sources.list.d/
#wget -q -O /tmp/key https://www.atomicorp.com/RPM-GPG-KEY.art.txt
#apt-key add /tmp/key
#apt-get update
#DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-unauthenticated ossec-hids-server
#sed -i -e 's/<rule id="31151" level="10" frequency="12" timeframe="90">/<rule id="31151" level="5" frequency="12" timeframe="90">/' /var/ossec/rules/web_rules.xml # deactivate active-response/firewall block when multiple http forbidden
#sed -i -e 's/\/var\/www\/logs\/access_log/\/var\/log\/apache2\/access.log/' /var/ossec/etc/ossec.conf
#sed -i -e 's/\/var\/www\/logs\/error_log/\/var\/log\/apache2\/error.log/' /var/ossec/etc/ossec.conf
#sed -i -e 's/<\/global>/<prelude_output>yes<\/prelude_output><prelude_profile>OSSEC-DMZ<\/prelude_profile><prelude_log_level>0<\/prelude_log_level><\/global>/' /var/ossec/etc/ossec.conf

# preconfig TLS and certbot
a2enmod ssl
a2ensite default-ssl.conf
echo -e "
email=admin@target.milxc
agree-tos=1
no-verify-ssl=1
" >> /etc/letsencrypt/cli.ini
