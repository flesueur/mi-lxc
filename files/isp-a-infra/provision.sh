#!/bin/bash
# ISP-A
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

# Hacker's mail account hacker@isp-a.milxc
useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 hacker` hacker || true
addgroup hacker mail
#mkdir /home/hacker/mail
#touch /home/hacker/mail/Drafts /home/hacker/mail/Queue /home/hacker/mail/Sent /home/hacker/mail/Trash


# manage isp-a.milxc zone
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y unbound
cp dns.conf /etc/unbound/unbound.conf.d/
