#!/bin/bash
# ISP-A infra
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

# Hacker's mail account hacker@isp-a.milxc
useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 hacker` hacker || true
adduser hacker mail
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
