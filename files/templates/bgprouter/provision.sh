#!/bin/bash
# Firewall template
set -e
if [ -z `hostname | grep lxc-infra` ] ; then exit 1; fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bird traceroute

# get iface name from internal ip
#iface=`ip route get $asip | awk '{ print $3; exit }'`
#echo $asip
#iface=`ifconfig | grep -B1 $asip | grep -o "^\w*"`

# customize bird config
sed -i "s/router id/router id $asn; #/" /etc/bird/bird.conf
sed -i "s/\#.*export all/\texport all/" /etc/bird/bird.conf
if [ ! -z $asdev ]
 then echo "protocol direct {   interface \"$asdev\"; } " >> /etc/bird/bird.conf
fi
IFS=';'
for i in $neighbors; do
  echo -e "
protocol bgp {
  local as $asn;
  neighbor $i;
  import all;
  export all;
}" >>  /etc/bird/bird.conf
done

service bird restart

# Disable DHCP and do DNS config
sed -i "s/.*dhcp.*//" /etc/network/interfaces
> /etc/resolv.conf

# iptables -t nat -A POSTROUTING -o eth2 ! -d 10.0.0.0/16 -j SNAT --to 192.168.10.1
# birdc show route all
# birdc show protocols
