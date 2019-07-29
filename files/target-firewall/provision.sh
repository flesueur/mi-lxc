#!/bin/bash
# Firewall
##############################################
# NOT FUNCTIONAL FOR DEBIAN 10 BUSTER !!!!!
##############################################

set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server
DEBIAN_FRONTEND=noninteractive UCF_FORCE_CONFFNEW=1 apt-get install -y prewikka prelude-manager prelude-correlator suricata

#DEB_VERSION=`cat /etc/debian_version | cut -d'.' -f1`
#if [ $DEB_VERSION -eq "10" ] # DEB 10 aka Buster stores password in /etc/dbconfig-common/prelude-manager.conf
#then
#  PASS=`grep -e "^dbc_dbpass=" /etc/dbconfig-common/prelude-manager.conf | cut -d'=' -f2`
#else # DEB 9 aka stretch stores password in /etc/prelude-manager/prelude-manager.conf
  PASS=`grep -e "^pass =" /etc/prelude-manager/prelude-manager.conf | cut -d'=' -f2`
#fi

sed -i "s/pass: prelude/pass:$PASS/" /etc/prewikka/prewikka.conf

sed -i "s/botcc.rules/local.rules/" /etc/suricata/suricata.yaml
#rm /etc/suricata/rules/*
cp local.rules /etc/suricata/rules/
sed -i -e 's/    HOME_NET:.*$/    HOME_NET: "[10.100.0.0\/16]"/' /etc/suricata/suricata.yaml

sed -i -e "s/RUN=no/RUN=yes/" /etc/default/prelude-manager || true # fails on buster, must be started manually
sed -i -e "s/RUN=no/RUN=yes/" /etc/default/prelude-correlator  || true # fails on buster, must be started manually

echo "listen = 10.100.0.1" >> /etc/prelude-manager/prelude-manager.conf


# only for stretch
sed -i -e "s/RUN=no/RUN=yes/" /etc/default/suricata
systemctl enable suricata
