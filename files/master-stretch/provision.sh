#!/bin/bash

#while [ ! `ip addr show dev eth0 | grep "inet "` ]
#do
#echo Waiting for IP
#sleep 1
#done
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

cp detect_proxy.sh /usr/local/sbin/
chmod a+x /usr/local/sbin/detect_proxy.sh
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y netcat
echo "Acquire::http::Proxy-Auto-Detect \"/usr/local/sbin/detect_proxy.sh\";" > /etc/apt/apt.conf.d/01proxy;

DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
DEBIAN_FRONTEND=noninteractive apt-get install -y dnsutils traceroute nftables ftp syslog-ng openssh-server bash-completion less leafpad mupdf xnest apache2 vim xfce4 firefox-esr tcpdump dsniff whois wireshark net-tools xfce4-terminal iptables iputils-ping netcat nmap socat curl wget unzip # keyboard-configuration  wireshark firmware-atheros firmware-misc-nonfree
apt-get clean
# firefox-esr epiphany-browser midori

# Localisation fr
echo "Europe/Paris" > /etc/timezone
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
dpkg-reconfigure -f noninteractive tzdata
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i -e 's/# fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen
echo 'LANG="fr_FR.UTF-8"'>/etc/default/locale
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=fr_FR.UTF-8


# Creation des utilisateurs
usermod -p `mkpasswd --method=sha-512 root` root
grep -q debian /etc/passwd || useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 debian` debian

#login ssh avec mot de passe
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
service ssh restart
