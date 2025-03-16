#!/bin/bash
# Firewall
# Kept on Buster, prewikka not working on Bullseye

set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server

# Some problems appeared when not installed in this forced order
DEBIAN_FRONTEND=noninteractive UCF_FORCE_CONFFNEW=1 apt-get install -y prewikka
DEBIAN_FRONTEND=noninteractive UCF_FORCE_CONFFNEW=1 apt-get install -y prelude-correlator suricata
DEBIAN_FRONTEND=noninteractive UCF_FORCE_CONFFNEW=1 apt-get install -y prelude-manager

PASS=`grep -e "^pass =" /etc/prelude-manager/prelude-manager.conf | cut -d'=' -f2`

sed -i "s/pass: prelude/pass:$PASS/" /etc/prewikka/prewikka.conf

sed -i "s/botcc.rules/local.rules/" /etc/suricata/suricata.yaml
#rm /etc/suricata/rules/*
cp local.rules /etc/suricata/rules/
sed -i -e 's/    HOME_NET:.*$/    HOME_NET: "[100.80.0.0\/16]"/' /etc/suricata/suricata.yaml

sed -i -e "s/RUN=no/RUN=yes/" /etc/default/prelude-manager || true # fails on buster, must be started manually
sed -i -e "s/RUN=no/RUN=yes/" /etc/default/prelude-correlator  || true # fails on buster, must be started manually

echo "listen = 100.80.0.1" >> /etc/prelude-manager/prelude-manager.conf


# only for stretch
sed -i -e "s/RUN=no/RUN=yes/" /etc/default/suricata
systemctl enable suricata


# Firewall setup
echo -e '#!/bin/sh
iptables -P FORWARD DROP
iptables -A FORWARD -i eth0 -o eth1 -d 100.80.1.2 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
exit 0' > /etc/rc.local
chmod +x /etc/rc.local
