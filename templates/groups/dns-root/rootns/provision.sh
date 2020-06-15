#!/bin/bash
# Root NS template
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

# disable systemd-resolved which conflicts with nsd
echo "DNSStubListener=no" >> /etc/systemd/resolved.conf
systemctl stop systemd-resolved

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nsd

# get root zone
wget "http://www.internic.net/domain/root.zone" -O /etc/nsd/root.zone

# customize root zone
# remove official roots
sed -i -e 's/^\.\s.*NS.*[a-m].root-servers.net.*//' /etc/nsd/root.zone
# add alternative milxc root
echo -e ".	518400	IN	NS	o.root-servers.net
o.root-servers.net	518400	IN	A 100.100.0.10
o.root-servers.net	518400	IN	AAAA     2001:db8:a000::10
" >> /etc/nsd/root.zone

echo -e ".	518400	IN	NS	p.root-servers.net
p.root-servers.net	518400	IN	A 100.100.1.10
p.root-servers.net	518400	IN	AAAA     2001:db8:a001::10
" >> /etc/nsd/root.zone


# add .milxc TLD served by 100.100.20.10
echo -e "milxc.	518400	IN	NS	ns.milxc.
ns.milxc.	518400	IN	A 100.100.20.10
ns.milxc.	518400	IN	AAAA 2001:db8:a020::10" >> /etc/nsd/root.zone

# customize nsd config
#echo -e "server:
#	ip-address: 127.0.0.1
echo -e "zone:
	name: \".\"
	zonefile: \"root.zone\"
" > /etc/nsd/nsd.conf

#service nsd restart
