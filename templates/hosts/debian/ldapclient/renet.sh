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

sed -i "s;^uri ldap://.*;uri ldap://$server/;" /etc/libnss-ldap.conf
sed -i "s;^uri ldap://.*;uri ldap://$server/;" /etc/pam_ldap.conf

sed -i "s;^base .*;base $dn;" /etc/libnss-ldap.conf
sed -i "s;^base .*;base $dn;" /etc/pam_ldap.conf
