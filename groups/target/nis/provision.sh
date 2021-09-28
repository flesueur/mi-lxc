#!/bin/bash
# Target NIS
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

groupadd employees
useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 commercial` -g employees commercial || true
addgroup commercial mail
useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 devdev` -g employees dev || true
useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 adminadmin` -g employees admin || true



# NIS server
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -d -y nis
mv /etc/resolv.conf /etc/resolv.conf.bak
DEBIAN_FRONTEND=noninteractive apt-get install -y nis
mv /etc/resolv.conf.bak /etc/resolv.conf
echo "target.milxc" > /etc/defaultdomain
domainname target.milxc
sed -i -e 's/NISSERVER=false/NISSERVER=master/' /etc/default/nis
sed -i -e 's/YPSERVARGS=/YPSERVARGS="-p 834"/' /etc/default/nis
make -C /var/yp
