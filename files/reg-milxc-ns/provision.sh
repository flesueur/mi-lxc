#!/bin/bash
# .milxc registry

set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

# disable systemd-resolved which conflicts with nsd
echo "DNSStubListener=no" >> /etc/systemd/resolved.conf
systemctl stop systemd-resolved

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nsd

echo -e "zone:
	name: \"milxc.\"
	zonefile: \"milxc.zone\"
" > /etc/nsd/nsd.conf

echo -e "\$TTL	86400
\$ORIGIN milxc.
@  1D  IN  SOA ns.milxc. hostmaster.milxc. (
			      2002022401 ; serial
			      3H ; refresh
			      15 ; retry
			      1w ; expire
			      3h ; nxdomain ttl
			     )
       IN  NS     ns.milxc.
ns    IN  A      10.10.20.10  ;name server definition
target.milxc.		IN	NS	ns.target.milxc.
ns.target.milxc.	IN	A 10.100.1.2
isp-a.milxc.	IN	NS	ns.isp-a.milxc.
ns.isp-a.milxc.	IN	A 10.150.1.2
" >> /etc/nsd/milxc.zone
