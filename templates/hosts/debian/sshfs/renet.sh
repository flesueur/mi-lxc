#!/bin/bash
# sshfs template
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

cp pam_mount.conf.xml /etc/security/
sed -i -e "s/\$server/$server/" /etc/security/pam_mount.conf.xml
