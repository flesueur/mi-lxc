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
sed -i -e 's/  driver = pam/  driver = pam\n  args = session=yes dovecot/' /etc/dovecot/conf.d/auth-system.conf.ext
echo "session     required      pam_mkhomedir.so skel=/etc/skel umask=0022" >> /etc/pam.d/common-session

if [ -z $domain ] ; then
  sed -i -e "s/mydestination = /#mydestination = /" /etc/postfix/main.cf
else
  sed -i -e "s/mydestination = /mydestination = $domain, /" /etc/postfix/main.cf
fi

if [ -z $mynetworks ] ; then
  sed -i -e "s/mynetworks = /mynetworks = 0.0.0.0\/0 [::]\/0 /" /etc/postfix/main.cf
else
  sed -i -e "s/mynetworks = /mynetworks = $mynetworks /" /etc/postfix/main.cf
fi

# create mail directories for already created users
for i in `ls /home`; do
  mkdir -p /home/$i/mail
  touch /home/$i/mail/Drafts /home/$i/mail/Queue /home/$i/mail/Sent /home/$i/mail/Trash
  echo -e "Trash\nDrafts\nQueue\nSent" >> /home/$i/mail/.subscriptions
  chown -R $i /home/$i/mail
done

# create mail directories for future (ie, LDAP) users
mkdir -p /etc/skel/mail
touch /etc/skel/mail/Drafts /etc/skel/mail/Queue /etc/skel/mail/Sent /etc/skel/mail/Trash
echo -e "Trash\nDrafts\nQueue\nSent" >> /etc/skel/mail/.subscriptions
