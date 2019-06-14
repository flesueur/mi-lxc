#!/bin/bash
# Transit A
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bird #postfix dovecot-imapd bird

#cp /mnt/lxc/backbone/interfaces /etc/network/interfaces.d/backbone
#echo "iface eth0 inet dhcp" >> /etc/network/interfaces

# echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo -e '#!/bin/bash\niptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE' > /etc/rc.local
chmod +x /etc/rc.local

echo "supersede domain-name-servers 10.10.10.10;" >> /etc/dhcp/dhclient.conf
echo "supersede domain-name \"internet.milxc\";" >> /etc/dhcp/dhclient.conf

#cp dns.conf /etc/unbound/unbound.conf.d/

# sed -i -e 's/ssl = no/ssl = yes/' /etc/dovecot/conf.d/10-ssl.conf
# echo "ssl_cert = </etc/ssl/certs/ssl-cert-snakeoil.pem" >> /etc/dovecot/conf.d/10-ssl.conf
# echo "ssl_key = </etc/ssl/private/ssl-cert-snakeoil.key" >> /etc/dovecot/conf.d/10-ssl.conf
# echo "disable_plaintext_auth = no" >> /etc/dovecot/conf.d/10-auth.conf
#
# sed -i -e 's/mydestination = /mydestination = internet.virt, /' /etc/postfix/main.cf
# sed -i -e 's/mynetworks = /mynetworks = 10.0.0.0\/24 /' /etc/postfix/main.cf

# customize bird config (BGP)
# sed -i "s/router id/router id 666; #/" /etc/bird/bird.conf
# sed -i "s/\#.*export all/\texport all/" /etc/bird/bird.conf
echo -e "
protocol static {
	route 0.0.0.0/0 via 10.180.0.1;
}
" >> /etc/bird/bird.conf
#
# protocol bgp {
# 	local as 30;
# 	neighbor 10.180.0.2 as 10;
# 	import all;
# 	export all;
# }
#
# protocol bgp {
# 	local as 30;
# 	neighbor 10.180.0.10 as 20;
# 	import all;
# 	export all;
# }
# " >> /etc/bird/bird.conf
