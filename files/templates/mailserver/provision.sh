#!/bin/bash
# Mail server template
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y postfix dovecot-imapd

sed -i -e 's/ssl = no/ssl = yes/' /etc/dovecot/conf.d/10-ssl.conf
echo "ssl_cert = </etc/ssl/certs/ssl-cert-snakeoil.pem" >> /etc/dovecot/conf.d/10-ssl.conf
echo "ssl_key = </etc/ssl/private/ssl-cert-snakeoil.key" >> /etc/dovecot/conf.d/10-ssl.conf
echo "disable_plaintext_auth = no" >> /etc/dovecot/conf.d/10-auth.conf

if [ -z $domain ] ; then
  sed -i -e "s/mydestination = /#mydestination = /" /etc/postfix/main.cf
else
  sed -i -e "s/mydestination = /mydestination = $domain, /" /etc/postfix/main.cf
fi

if [ -z $mynetworks ] ; then
  sed -i -e "s/mynetworks = /#mynetworks = /" /etc/postfix/main.cf
else
  sed -i -e "s/mynetworks = /mynetworks = $mynetworks /" /etc/postfix/main.cf
fi
