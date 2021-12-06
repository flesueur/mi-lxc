#!/bin/sh
# BGP router template
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

#sed -i "s/dhcp/manual/" /etc/network/interfaces

#echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
apk update
apk add bird iptables nftables iproute2-ss openssh-server
rc-update add bird
rc-update add sshd



echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
echo -e "\n*\t*\t*\t*\t*\t/sbin/sysctl -p" >> /etc/crontabs/root



# get iface name from internal ip
#iface=`ip route get $asip | awk '{ print $3; exit }'`
#echo $asip
#iface=`ifconfig | grep -B1 $asip | grep -o "^\w*"`

# customize bird config
#sed -i "s/router id/router id $asn; #/" /etc/bird.conf
#sed -i "s/\#.*export all/\texport all/" /etc/bird.conf

echo "router id $asn;" >> /etc/bird.conf

OLDIFS=$IFS
if [ ! -z $asdev ]
 then
 IFS=';'
 for i in $asdev; do
   echo "protocol direct {  ipv4; interface \"$i\"; } " >> /etc/bird.conf
 done
fi
IFS=';'
for i in $neighbors4; do
  echo -e "
protocol bgp {
  local as $asn;
  neighbor $i;
  ipv4 {
    import all;
    export all;
  };
}" >>  /etc/bird.conf
done

# bird6
IFS=$OLDIFS
if [ ! -z $asdev ]
 then
 IFS=';'
 for i in $asdev; do
   echo "protocol direct {  ipv6; interface \"$i\"; } " >> /etc/bird.conf
 done
fi
IFS=';'
for i in $neighbors6; do
  echo -e "
protocol bgp {
  local as $asn;
  neighbor $i;
  ipv6 {
    import all;
    export all;
  };
}" >>  /etc/bird.conf
done

service bird restart

# iptables -t nat -A POSTROUTING -o eth2 ! -d 10.0.0.0/16 -j SNAT --to 192.168.10.1
# birdc show route all
# birdc show protocols
