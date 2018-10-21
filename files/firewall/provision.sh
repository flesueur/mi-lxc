#!/bin/bash
# BACKBONE

if [ -z `hostname | grep lxc-infra` ] ; then exit 1; fi

DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server
DEBIAN_FRONTEND=noninteractive apt-get install -y prewikka prelude-manager prelude-correlator suricata

PASS=`grep -e "^pass =" /etc/prelude-manager/prelude-manager.conf | cut -d'=' -f2`
sed -i "s/pass: prelude/pass:$PASS/" /etc/prewikka/prewikka.conf
