#!/bin/bash
# BACKBONE
set -e
if [ -z `hostname | grep lxc-infra` ] ; then exit 1; fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y unbound postfix dovecot-imapd bird

cp /mnt/lxc/backbone/interfaces /etc/network/interfaces.d/backbone

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo -e '#!/bin/bash\niptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE\nip route add 192.168.0.0/16 via 10.0.0.2' > /etc/rc.local
chmod +x /etc/rc.local

echo "supersede domain-name-servers 10.0.0.1;" >> /etc/dhcp/dhclient.conf
echo "supersede domain-name \"internet.virt\";" >> /etc/dhcp/dhclient.conf

cp /mnt/lxc/backbone/dns.conf /etc/unbound/unbound.conf.d/

sed -i -e 's/ssl = no/ssl = yes/' /etc/dovecot/conf.d/10-ssl.conf
echo "ssl_cert = </etc/ssl/certs/ssl-cert-snakeoil.pem" >> /etc/dovecot/conf.d/10-ssl.conf
echo "ssl_key = </etc/ssl/private/ssl-cert-snakeoil.key" >> /etc/dovecot/conf.d/10-ssl.conf
echo "disable_plaintext_auth = no" >> /etc/dovecot/conf.d/10-auth.conf

sed -i -e 's/mydestination = /mydestination = internet.virt, /' /etc/postfix/main.cf
sed -i -e 's/mynetworks = /mynetworks = 10.0.0.0\/24 /' /etc/postfix/main.cf

useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 hacker` hacker || true
addgroup hacker mail

# customize bird config (BGP)
sed -i "s/router id/router id 666; #/" /etc/bird/bird.conf
sed -i "s/\#.*export all/\texport all/" /etc/bird/bird.conf
echo -e "
protocol static {
	route 0.0.0.0/0 via 10.0.0.1;
}

protocol bgp {
	local as 10;
	neighbor 10.0.0.10 as 1;
	import all;
	export all;
}

protocol bgp {
	local as 10;
	neighbor 10.0.0.20 as 2;
	import all;
	export all;
}
" >> /etc/bird/bird.conf
