#!/bin/sh
# Transit A with alpine
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
apk update
apk add bird iptables
rc-update add bird

# echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo -e '#!/bin/sh\niptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE' > /etc/local.d/iptables.start
chmod +x /etc/local.d/iptables.start
rc-update add local

# keep DHCP on eth0
touch /etc/network/keepdhcp

# Force lxc bridged interface metric (else, it grows to 200+interface_index, which can be large with successive  stop/start)
# This metric must be lower than the one exported by BGP for the default route (static part below)
mkdir /etc/udhcpc
echo "IF_METRIC=200" > /etc/udhcpc/udhcpc.conf

#echo "supersede domain-name-servers 10.10.10.10;" >> /etc/dhcp/dhclient.conf
#echo "supersede domain-name \"internet.milxc\";" >> /etc/dhcp/dhclient.conf


# customize bird config (BGP)
sed -i "s/protocol kernel {/protocol kernel { metric 2000;/" /etc/bird.conf
# sed -i "s/\#.*export all/\texport all/" /etc/bird/bird.conf
echo -e "
protocol static {
	ipv4;
	route 0.0.0.0/0 via 100.64.0.1;
}
" >> /etc/bird.conf
