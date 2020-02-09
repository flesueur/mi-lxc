#!/bin/bash
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`
set -e

# Copie de qques fichiers
#cp /vagrant/files/sources.list /etc/apt/sources.list
cp /vagrant/files/keyboard /etc/default/keyboard
echo "USE_LXC_BRIDGE=\"true\"" > /etc/default/lxc-net

# MAJ et install
apt-get --allow-releaseinfo-change update
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
DEBIAN_FRONTEND=noninteractive apt-get install -y apt-cacher-ng
echo "Acquire::http::Proxy \"http://127.0.0.1:3142\";" > /etc/apt/apt.conf.d/01proxy;  # utilisation de apt-cacher-ng
#data=`uname -r`
#arch=${data##*-}
DEBIAN_FRONTEND=noninteractive apt-get install -y linux-headers-`dpkg --print-architecture` curl dkms apt-cacher-ng python3-pygraphviz python3-pil imagemagick linux-headers-amd64 curl git lxc python3-lxc apache2 vim xfce4 lightdm firefox-esr gnome-terminal tcpdump dsniff whois postgresql wireshark dkms net-tools zerofree mousepad # keyboard-configuration  wireshark
apt-get clean
# linux-headers-4.9.0-7-amd64 firmware-atheros firmware-misc-nonfree

# vbox guest utils
VERSION=`curl https://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT`
curl https://download.virtualbox.org/virtualbox/$VERSION/VBoxGuestAdditions_$VERSION.iso -o /tmp/vbox.iso
mount -o loop /tmp/vbox.iso /mnt
/mnt/VBoxLinuxAdditions.run || true # vboxsf module will fail to load before reboot, expected behavior
/sbin/rcvboxadd quicksetup all || true

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
useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 debian` debian

# augmentation de la taille de /run si lowmem
#echo "tmpfs /run tmpfs nosuid,noexec,size=26M 0  0" >> /etc/fstab
#mount -o remount /run

#login ssh avec mot de passe
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config



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


reboot
