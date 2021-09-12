#!/bin/bash
# MICA infra
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

# Hacker's mail account hacker@isp-a.milxc
useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 ca` ca || true
addgroup ca mail
#mkdir /home/hacker/mail
#touch /home/hacker/mail/Drafts /home/hacker/mail/Queue /home/hacker/mail/Sent /home/hacker/mail/Trash

# disable systemd-resolved which conflicts with nsd
echo "DNSStubListener=no" >> /etc/systemd/resolved.conf
systemctl stop systemd-resolved

# manage isp-a.milxc zone
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y unbound
cp dns.conf /etc/unbound/unbound.conf.d/


# Install smallstep CA / ACME server
cd /tmp
wget https://github.com/smallstep/cli/releases/download/v0.13.3/step-cli_0.13.3_amd64.deb
dpkg -i step-cli_0.13.3_amd64.deb
wget https://github.com/smallstep/certificates/releases/download/v0.13.3/step-certificates_0.13.3_amd64.deb
dpkg -i step-certificates_0.13.3_amd64.deb

# step ca init
# step ca root root.crt
# step ca provisioner add acme --type ACME
# certbot certonly -n --standalone -d www.target.milxc   --server https://www.mica.milxc/acme/acme/directory --agree-tos --email "fr@fr.fr"
