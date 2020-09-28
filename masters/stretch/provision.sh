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
DEBIAN_FRONTEND=noninteractive apt-get install -y dnsutils traceroute nftables ftp syslog-ng openssh-server bash-completion less leafpad mupdf xnest xserver-xephyr apache2 vim xfce4 firefox-esr tcpdump dsniff whois wireshark net-tools xfce4-terminal iptables iputils-ping netcat nmap socat curl wget unzip # keyboard-configuration  wireshark firmware-atheros firmware-misc-nonfree
apt-get clean
# firefox-esr epiphany-browser midori

# Disable user_ns which crashes firefox, see https://bugzilla.mozilla.org/show_bug.cgi?id=1565972
echo "MOZ_ASSUME_USER_NS=0" >> /etc/environment

# Localisation du $LANG, en par défaut, timezone Paris
if [ -z $HOSTLANG ] ; then
  HOSTLANG="en_US.UTF-8"
fi
echo "Europe/Paris" > /etc/timezone
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
dpkg-reconfigure -f noninteractive tzdata
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i -e "s/# $HOSTLANG /$HOSTLANG /" /etc/locale.gen
echo "LANG=\"$HOSTLANG\"">/etc/default/locale
dpkg-reconfigure --frontend=noninteractive locales || true  # don't fail for a locales problem
update-locale LANG=$HOSTLANG || true   # don't fail for a locales problem

# prevents "mesg: ttyname failed: No such device" error message when attaching
sed -i "/mesg n/d" /root/.profile
#echo "echo -e \"\n  Successfully attached to \`hostname | cut -d'-' -f'2-'\`\n\"" > /etc/profile.d/milxc_attach.sh

# XFCE4 panel: use default config
# source: https://forum.xfce.org/viewtopic.php?pid=36585#p36585
cp /etc/xdg/xfce4/panel/default.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml

# Creation des utilisateurs
usermod -p `mkpasswd --method=sha-512 root` root
grep -q debian /etc/passwd || useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 debian` debian

#login ssh avec mot de passe
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
service ssh restart
