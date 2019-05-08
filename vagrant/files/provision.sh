#!/bin/bash

# Copie de qques fichiers
cp /vagrant/files/sources.list /etc/apt/sources.list
cp /vagrant/files/keyboard /etc/default/keyboard
cp /vagrant/files/lxc-net /etc/default/lxc-net


# MAJ et install
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y linux-headers-`uname -r` curl dkms apt-cacher-ng
# guest utils
VERSION=`curl https://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT`
curl https://download.virtualbox.org/virtualbox/$VERSION/VBoxGuestAdditions_$VERSION.iso -o /tmp/vbox.iso
mount -o loop /tmp/vbox.iso /mnt
/mnt/VBoxLinuxAdditions.run

echo "Acquire::http::Proxy \"http://127.0.0.1:3142\";" > /etc/apt/apt.conf.d/01proxy;  # utilisation de apt-cacher-ng

# MAJ et install
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pygraphviz imagemagick linux-headers-4.9.0-7-amd64 linux-headers-amd64 curl git lxc python3-lxc apache2 vim xfce4 lightdm firefox-esr gnome-terminal firmware-atheros firmware-misc-nonfree tcpdump dsniff whois postgresql wireshark dkms net-tools zerofree # keyboard-configuration  wireshark
apt-get clean


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
useradd -m -s "/bin/bash" -p `mkpasswd --method=sha-512 debian` debian || true

# augmentation de la taille de /run si lowmem
#echo "tmpfs /run tmpfs nosuid,noexec,size=26M 0  0" >> /etc/fstab
#mount -o remount /run

#login ssh avec mot de passe
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config



#/vagrant/files/VBoxLinuxAdditions.run

# autorisation du routing
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
service lxc restart
iptables -A INPUT -p tcp --dport 3142 -i lxcbr0 -j ACCEPT # pour le proxy APT
cd /root
git clone https://github.com/flesueur/mi-lxc
cd mi-lxc
./mi-lxc.py create

reboot
