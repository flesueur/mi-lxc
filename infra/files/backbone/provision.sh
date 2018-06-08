#!/bin/bash
# BACKBONE

DEBIAN_FRONTEND=noninteractive apt-get install -y unbound postfix dovecot-imapd

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
