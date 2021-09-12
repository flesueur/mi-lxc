#!/bin/bash
# Target LDAP
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

#groupadd employees
#useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 commercial` -g employees commercial || true
#addgroup commercial mail
#useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 devdev` -g employees dev || true
#useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 adminadmin` -g employees admin || true

# LDAP server
apt-get update

echo -e "slapd	slapd/password1	password	root
slapd	slapd/password2	password	root
slapd	slapd/domain	string	target.milxc
slapd	shared/organization	string	target.milxc" | debconf-set-selections

DEBIAN_FRONTEND=noninteractive apt-get install -y slapd ldap-utils

echo -e "dn: ou=People,dc=target,dc=milxc
objectClass: organizationalUnit
objectClass: top
ou: People

dn: ou=Group,dc=target,dc=milxc
objectClass: organizationalUnit
objectClass: top
ou: Group"|ldapadd -cxD cn=admin,dc=target,dc=milxc -w root

addgroup(){
  group=$1
  gid=$2
  echo -e "dn: cn=$group,ou=Group,dc=target,dc=milxc
objectClass: top
objectClass: posixGroup
gidNumber: $gid" |ldapadd -cxD cn=admin,dc=target,dc=milxc -w root
}

adduser(){
  user=$1
  pass=`slappasswd -s $2`
  uid=$3
  gid=$4
  echo -e "dn: uid=$user,ou=People,dc=target,dc=milxc
objectClass: top
objectClass: account
objectClass: posixAccount
objectClass: shadowAccount
cn: $user
uid: $user
uidNumber: $uid
gidNumber: $gid
homeDirectory: /home/$user
loginShell: /bin/bash
gecos: $user
userPassword: $pass" |ldapadd -cxD cn=admin,dc=target,dc=milxc -w root
}

addtogroup(){
  user=$1
  group=$2
  echo -e "dn: cn=$group,ou=Group,dc=target,dc=milxc
changetype: modify
add: memberUid
memberUid: $user" |ldapadd -cxD cn=admin,dc=target,dc=milxc -w root
}

#cat addgroup.ldif | sed "s/\$group/employees/" | sed "s/\$gid/1100/" | ldapadd -cxD cn=admin,dc=target,dc=milxc -w root
#cat adduser.ldif | sed "s?\$pass?`slappasswd -s com`?" | sed "s/\$user/com/" | sed "s/\$uid/1100/" | sed "s/\$gid/1100/" | ldapadd -cxD cn=admin,dc=target,dc=milxc -w root
#cat addtogroup.ldif | sed "s/\$user/com/" | sed "s/\$group/employees/" | ldapmodify -cxD cn=admin,dc=target,dc=milxc -w root

addgroup employees 1001
addgroup mail `getent group | grep mail | cut -d':' -f 3`
adduser commercial commercial 1001 1001
adduser dev dev 1002 1001
adduser admin admin 1003 1001
addtogroup commercial mail



# LDAP : https://www.ossramblings.com/preseed_your_apt_get_for_unattended_installs
# apt-get install debconf-utils
# debconf-get-selections | grep slap > ldap.seed
# ajout du pass dans ldap.seed
# debconf-set-selections ./ldap.seed
# cat adduser.ldif | sed "s?\$pass?`slappasswd -s toto`?"
