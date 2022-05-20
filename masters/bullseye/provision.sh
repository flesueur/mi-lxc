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

# prevent apt cache (https://sleeplessbeastie.eu/2017/10/02/how-to-disable-the-apt-cache/ https://askubuntu.com/questions/81179/how-to-prevent-apt-get-aptitude-keeping-a-cache)
# echo -e 'Dir::Cache "";\nDir::Cache::archives "";' | tee /etc/apt/apt.conf.d/00_disable-cache-directories
echo -e 'Dir::Cache::pkgcache "";\nDir::Cache::srcpkgcache "";' > /etc/apt/apt.conf.d/00_disable-cache-files
echo 'DPkg::Post-Invoke {"/bin/rm -f /var/cache/apt/archives/*.deb || true";};' > /etc/apt/apt.conf.d/autoclean

apt-get clean

cp detect_proxy.sh /usr/local/sbin/
chmod a+x /usr/local/sbin/detect_proxy.sh
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y netcat-traditional
echo "Acquire::http::Proxy-Auto-Detect \"/usr/local/sbin/detect_proxy.sh\";" > /etc/apt/apt.conf.d/01proxy;

# Preseed wireshark for non-root users
echo -e "wireshark-common wireshark-common/install-setuid	boolean	true" | debconf-set-selections

echo "Domains=milxc" >> /etc/systemd/resolved.conf

DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
DEBIAN_FRONTEND=noninteractive apt-get install -y man dnsutils traceroute nftables ftp syslog-ng openssh-server bash-completion less mousepad mupdf xnest xserver-xephyr apache2 vim lxde-core lxterminal firefox-esr tcpdump dsniff whois wireshark net-tools iptables iputils-ping netcat-traditional nmap socat curl wget unzip xscreensaver # keyboard-configuration  wireshark firmware-atheros firmware-misc-nonfree xfce4  xfce4-terminal xscreensaver # could be with --no-install-recommends
# apt-get clean
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
# cp /etc/xdg/xfce4/panel/default.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml

# Creation des utilisateurs
usermod -p `mkpasswd --method=sha-512 root` root
grep -q debian /etc/passwd || useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 debian` debian
usermod -a -G wireshark debian

#login ssh avec mot de passe
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
service ssh restart

# unprivileged ping
chmod u+s /bin/ping

# remove colord which makes XFCE prompt for a password at first display
# DEBIAN_FRONTEND=noninteractive apt-get remove -y colord
# DEBIAN_FRONTEND=noninteractive apt-get autoremove -y

# remove pulseaudio
DEBIAN_FRONTEND=noninteractive apt-get remove -y pulseaudio
DEBIAN_FRONTEND=noninteractive apt-get autoremove -y

# better palette for lxterminal
sed -i "s/Monospace 10/Monospace 12/" /usr/share/lxterminal/lxterminal.conf
cat lxterminal.conf >> /usr/share/lxterminal/lxterminal.conf

# limit journald log size
mkdir -p /etc/systemd/journald.conf.d
echo "[Journal]" > /etc/systemd/journald.conf.d/sizelimit.conf
echo "SystemMaxUse=20M" >> /etc/systemd/journald.conf.d/sizelimit.conf
echo "SystemMaxFileSize=2M" >> /etc/systemd/journald.conf.d/sizelimit.conf
