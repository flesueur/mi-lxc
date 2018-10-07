#!/bin/bash
# DMZ

if [ -z `hostname | grep lxc-infra` ] ; then exit 1; fi

useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 commercial` commercial || true
addgroup commercial mail
useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 devdev` dev || true
useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 adminadmin` admin || true



# NIS server
DEBIAN_FRONTEND=noninteractive apt-get install -y nis
echo "target.virt" > /etc/defaultdomain
domainname target.virt
sed -i -e 's/NISSERVER=false/NISSERVER=master/' /etc/default/nis
make -C /var/yp
