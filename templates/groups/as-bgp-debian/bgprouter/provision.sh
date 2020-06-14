#!/bin/bash
# BGP router template
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bird traceroute

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf



# get iface name from internal ip
#iface=`ip route get $asip | awk '{ print $3; exit }'`
#echo $asip
#iface=`ifconfig | grep -B1 $asip | grep -o "^\w*"`

# customize bird config
sed -i "s/router id/router id $asn; #/" /etc/bird/bird.conf
sed -i "s/\#.*export all/\texport all/" /etc/bird/bird.conf
if [ ! -z $asdev ]
 then
 IFS=';'
 for i in $asdev; do
   echo "protocol direct {   interface \"$i\"; } " >> /etc/bird/bird.conf
 done
fi
IFS=';'
for i in $neighbors4; do
  echo -e "
protocol bgp {
  local as $asn;
  neighbor $i;
  import all;
  export all;
}" >>  /etc/bird/bird.conf
done

# customize bird6 config
sed -i "s/router id/router id $asn; #/" /etc/bird/bird6.conf
sed -i "s/\#.*export all/\texport all/" /etc/bird/bird6.conf
if [ ! -z $asdev ]
 then
 IFS=';'
 for i in $asdev; do
   echo "protocol direct {   interface \"$i\"; } " >> /etc/bird/bird6.conf
 done
fi
IFS=';'
for i in $neighbors6; do
  echo -e "
protocol bgp {
  local as $asn;
  neighbor $i;
  import all;
  export all;
}" >>  /etc/bird/bird6.conf
done

service bird restart
service bird6 restart

# iptables -t nat -A POSTROUTING -o eth2 ! -d 10.0.0.0/16 -j SNAT --to 192.168.10.1
# birdc show route all
# birdc show protocols
