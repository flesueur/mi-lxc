#!/bin/bash
# DMZ
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
if [ $DEB_VERSION -eq "10" ] # DEB 10 aka Buster
then
  DEBIAN_FRONTEND=noninteractive apt-get install -y certbot nsd dovecot-imapd proftpd apt-transport-https wget prelude-utils libprelude-dev build-essential php7.3-mbstring php7.3 libevent-dev libpcre2-dev zlib1g-dev libssl-dev
else # DEB 9 aka stretch
  DEBIAN_FRONTEND=noninteractive apt-get install -y nsd dovecot-imapd proftpd apt-transport-https wget libprelude2 libprelude-dev build-essential  php7.0-mbstring php7.0
fi

# DNS server
echo -e "zone:
	name: \"target.milxc.\"
	zonefile: \"target.milxc.zone\"
" > /etc/nsd/nsd.conf

cp dns.conf /etc/nsd/target.milxc.zone

#useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 commercial` commercial || true
#addgroup commercial mail
#mkdir /home/commercial/mail
#touch /home/commercial/mail/Drafts /home/commercial/mail/Queue /home/commercial/mail/Sent /home/commercial/mail/Trash
# allow to create homedirs when ldap authentication succeeds in IMAP - pam_mkhomedir does not work with imap auth (no pam-session in imap), other solution would be to manually create needed directories
echo -e '#!/bin/sh\nchmod 777 /home\nchmod o+t /home\nexit 0' > /etc/rc.local
chmod +x /etc/rc.local


# Install de dokuwiki
rm -f /var/www/html/index.html
#cp -ar /mnt/lxc/dmz/dokuwiki/* /var/www/html/
wget https://github.com/splitbrain/dokuwiki/archive/release_stable_2018-04-22b.tar.gz -O /tmp/dokuwiki.tar.gz
tar zxf /tmp/dokuwiki.tar.gz -C /var/www/html --strip 1
echo "sh      application/x-sh" >> /var/www/html/conf/mime.conf
PASS=`mkpasswd -5 superman`
echo "admin:$PASS:admin:admin@target.milxc:admin,user" >> /var/www/html/conf/users.auth.php
echo "* @ALL  1" > /var/www/html/conf/acl.auth.php
echo "* @user  8" >> /var/www/html/conf/acl.auth.php
cp doku/local.php /var/www/html/conf/
cp doku/start.txt /var/www/html/data/pages/
chown -R www-data /var/www/html/*
a2enmod headers
echo "RequestHeader unset If-Modified-Since" >> /etc/apache2/apache2.conf

# Install de OSSEC avec support prelude
cd /tmp
wget https://github.com/ossec/ossec-hids/archive/3.4.0.tar.gz
tar zxvf 3.4.0.tar.gz
cd ossec-hids-3.4.0
cp $DIR/preloaded-vars.conf etc/
USE_PRELUDE=yes ./install.sh

sed -i -e 's/<rule id="31151" level="10" frequency="12" timeframe="90">/<rule id="31151" level="5" frequency="12" timeframe="90">/' /var/ossec/rules/web_rules.xml # deactivate active-response/firewall block when multiple http forbidden
sed -i -e 's/\/var\/www\/logs\/access_log/\/var\/log\/apache2\/access.log/' /var/ossec/etc/ossec.conf
sed -i -e 's/\/var\/www\/logs\/error_log/\/var\/log\/apache2\/error.log/' /var/ossec/etc/ossec.conf
sed -i -e 's/<\/global>/<prelude_output>no<\/prelude_output>\n<prelude_profile>OSSEC-DMZ<\/prelude_profile>\n<prelude_log_level>0<\/prelude_log_level>\n<\/global>/' /var/ossec/etc/ossec.conf
sed -i -e 's/<frequency>79200<\/frequency>/<frequency>60<\/frequency>/' /var/ossec/etc/ossec.conf
sed -i -e 's/<directories check_all="yes">/<directories check_all="yes" realtime="no">/' /var/ossec/etc/ossec.conf
sed -i -e 's/server-addr = 127.0.0.1/server-addr = 10.100.0.1/' /etc/prelude/default/client.conf

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

# preconfig TLS
a2enmod ssl
a2ensite default-ssl.conf
