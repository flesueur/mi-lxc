#!/bin/bash
# ldapclient template
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

IFS='.'
dn=""
for i in $domain; do
  dn="$dn, dc=$i"
done
dn=`echo $dn | cut -c3- -`
#echo $dn


# LDAP client
apt-get update
#cp ldap.seed /tmp/
#sed -i -e "s/\$server/$server/" /tmp/ldap.seed

echo -e "libnss-ldap	shared/ldapns/base-dn	string	$dn
libpam-ldap	shared/ldapns/base-dn	string	$dn
libnss-ldap	shared/ldapns/ldap-server	string	ldap://$server/
libpam-ldap	shared/ldapns/ldap-server	string	ldap://$server/" | debconf-set-selections

DEBIAN_FRONTEND=noninteractive apt-get install -y libnss-ldap libpam-ldap
sed -i "s/^\(passwd:.*\)$/\1 ldap/" /etc/nsswitch.conf
sed -i "s/^\(group:.*\)$/\1 ldap/" /etc/nsswitch.conf
sed -i "s/^\(shadow:.*\)$/\1 ldap/" /etc/nsswitch.conf
#sed -i -e 's/compat/compat ldap/' /etc/nsswitch.conf

echo "bind_timelimit 2" >> /etc/pam_ldap.conf
echo "bind_policy soft" >> /etc/pam_ldap.conf
echo "bind_timelimit 2" >> /etc/libnss-ldap.conf
echo "bind_policy soft" >> /etc/libnss-ldap.conf

# auto create home dir when an LDAP user connects for the first time
# it absolutely needs to be before "pam_mount" because it creates a folder in the home dir to mount the share,
# and thus create the homedir if it doesn't already exist but mkhomedir won't run if the home dir already exists...
sed -i '/pam_mount.so/i session required pam_mkhomedir.so skel=\/etc\/skel umask=0022' /etc/pam.d/common-session
