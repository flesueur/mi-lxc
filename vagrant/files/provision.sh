#!/bin/bash
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`
set -e

# Copie de qques fichiers
#cp /vagrant/files/sources.list /etc/apt/sources.list
cp /vagrant/files/keyboard /etc/default/keyboard
# echo "USE_LXC_BRIDGE=\"true\"" > /etc/default/lxc-net

# Lock grub (https://www.mail-archive.com/debian-bugs-dist@lists.debian.org/msg1758060.html)
DEBIAN_FRONTEND=noninteractive apt-mark hold grub*

# MAJ et install
sed -i -e 's/main/main contrib non-free/' /etc/apt/sources.list
apt-get --allow-releaseinfo-change update
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
DEBIAN_FRONTEND=noninteractive apt-get install -y apt-cacher-ng
echo "Acquire::http::Proxy \"http://127.0.0.1:3142\";" > /etc/apt/apt.conf.d/01proxy;  # utilisation de apt-cacher-ng
#data=`uname -r`
#arch=${data##*-}
DEBIAN_FRONTEND=noninteractive apt-get install -y linux-headers-`dpkg --print-architecture` virtualbox-guest-additions-iso dynamips screen curl dkms python3-pygraphviz python3-pil imagemagick linux-headers-amd64 git lxc python3-lxc vim xfce4 lightdm firefox-esr xfce4-terminal tcpdump whois dkms net-tools mousepad wireshark xserver-xorg # apt-cacher-ng zerofree wireshark dsniff apache2 postgresql keyboard-configuration  wireshark
apt-get clean
# linux-headers-4.9.0-7-amd64 firmware-atheros firmware-misc-nonfree

# vbox guest utils
#VERSION=`curl https://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT`
#curl https://download.virtualbox.org/virtualbox/$VERSION/VBoxGuestAdditions_$VERSION.iso -o /tmp/vbox.iso
#mount -o loop /tmp/vbox.iso /mnt
mount -o loop /usr/share/virtualbox/VBoxGuestAdditions.iso /mnt
/mnt/VBoxLinuxAdditions.run || true # vboxsf module will fail to load before reboot, expected behavior
/sbin/rcvboxadd quicksetup all || true
umount /mnt

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


# Creation des utilisateurs
usermod -p `mkpasswd --method=sha-512 root` root
useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 debian` debian || true # don't fail if user already exists

# augmentation de la taille de /run si lowmem
#echo "tmpfs /run tmpfs nosuid,noexec,size=26M 0  0" >> /etc/fstab
#mount -o remount /run

# Désactivation de la mise en veille de l'écran
mkdir -p /etc/X11/xorg.conf.d/
cp /vagrant/files/10-monitor.conf /etc/X11/xorg.conf.d/
# mv /etc/xdg/autostart/light-locker.desktop /etc/xdg/autostart/light-locker.desktop.bak
DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y light-locker

#login ssh avec mot de passe
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config

# VPN and x2go
# echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
# echo -e "x2goserver-desktopsharing	x2goserver-desktopsharing/use-existing-group-for-sharing	boolean	false
# x2goserver-desktopsharing	x2goserver-desktopsharing/auto-start-on-logon	boolean	true
# x2goserver-desktopsharing	x2goserver-desktopsharing/auto-activate-on-logon	boolean	true
# x2goserver-desktopsharing	x2goserver-desktopsharing/create-group-for-sharing	boolean	true
# x2goserver-desktopsharing	x2goserver-desktopsharing/group-sharing	string	x2godesktopsharing" | debconf-set-selections
#
# DEBIAN_FRONTEND=noninteractive apt-get install -y x2goserver-desktopsharing openvpn
#
# echo "ip addr show dev tun1 1>/dev/null 2>&1 && (echo -n 'IP VPN : ' && ip -4 addr show tun1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')" >> /root/.bashrc
#
# source vpn.conf
# echo -e "$LOGIN\n$PASSWORD" > /root/.pass
# chmod 600 /root/.pass
# wget "$CACERT" -O /root/.ca.crt
# echo -e "#!/bin/sh
# openvpn --remote $SERVER --dev tun1 --client --ca /root/.ca.crt --auth-user-pass /root/.pass --comp-lzo --mute-replay-warnings &
# exit 0" > /etc/rc.local
# chmod +x /etc/rc.local
# Fin VPN/X2GO

#/vagrant/files/VBoxLinuxAdditions.run

# autorisation du routing
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
# fs.inotify.max_queued_events = 16384
# fs.inotify.max_user_instances = 128
# fs.inotify.max_user_watches = 8192
echo -e "fs.inotify.max_queued_events=1048576\nfs.inotify.max_user_instances=1048576\nfs.inotify.max_user_watches=1048576" >> /etc/sysctl.conf
sysctl -p
service lxc restart
iptables -A INPUT -p tcp --dport 3142 -i lxcbr0 -j ACCEPT # pour le proxy APT
cd /root
#git clone https://github.com/flesueur/mi-lxc
cd mi-lxc
./mi-lxc.py create

# updates PATH with su
echo "ALWAYS_SET_PATH yes" >> /etc/login.defs

# enable bash autocompletion
cp milxc-completion.bash /etc/bash_completion.d/
echo -e "
# enable bash completion in interactive shells
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi" >> /etc/bash.bashrc

# XFCE4 panel: use default config
# source: https://forum.xfce.org/viewtopic.php?pid=36585#p36585
cp /etc/xdg/xfce4/panel/default.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml

reboot
