#!/bin/bash
# Firewall
set -e
if [ -z `hostname | grep lxc-infra` ] ; then exit 1; fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server
DEBIAN_FRONTEND=noninteractive apt-get install -y prewikka prelude-manager prelude-correlator suricata

PASS=`grep -e "^pass =" /etc/prelude-manager/prelude-manager.conf | cut -d'=' -f2`
sed -i "s/pass: prelude/pass:$PASS/" /etc/prewikka/prewikka.conf

sed -i "s/botcc.rules/local.rules/" /etc/suricata/suricata.yaml
#rm /etc/suricata/rules/*
cp /mnt/lxc/firewall/local.rules /etc/suricata/rules/
sed -i -e 's/    HOME_NET:.*$/    HOME_NET: "[192.168.0.0\/16]"/' /etc/suricata/suricata.yaml

sed -i -e "s/RUN=no/RUN=yes/" /etc/default/prelude-manager
sed -i -e "s/RUN=no/RUN=yes/" /etc/default/prelude-correlator
echo "listen = 192.168.0.1" >> /etc/prelude-manager/prelude-manager.conf
