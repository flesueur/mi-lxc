#!/bin/bash
# Commercial

if [ -z `hostname | grep lxc-infra` ] ; then exit 1; fi

# systemctl set-default graphical.target

# DEBIAN_FRONTEND=noninteractive apt-get install -y thunderbird


#cp -ar /mnt/lxc/commercial/homedir/* /home/debian/
#ln -sf /home/debian/background.jpg /usr/share/images/desktop-base/default
mkdir /home/commercial
mkdir -p /home/commercial/.ssh

tar zxvf /mnt/lxc/commercial/thunderbird.tar.gz -C /home/commercial/

chown -R 1001:1001 /home/commercial

# remove nmap binary
rm /usr/bin/nmap

# Disable DHCP and do DNS config
#sed -i "s/.*dhcp.*//" /etc/network/interfaces
#echo -e "domain target.virt\nsearch target.virt\nnameserver 192.168.1.2" > /etc/resolv.conf

# NIS client
#DEBIAN_FRONTEND=noninteractive apt-get install -y nis
#echo "target" > /etc/defaultdomain
#echo "ypserver 192.168.1.2" >> /etc/yp.conf
#sed -i -e 's/compat/compat nis/' /etc/nsswitch.conf


echo -e "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA5gMaCpCamrAgfNy/P2g/Q++fNzStR6CLiSb+Bquq+h82iJIH
G2lFs4r7sj1xImOnmlQCRy6+CFDDnxq9stWqeR5VzSfmZPY38HF0Q8Fp50ST66JC
H5bqLT4xgOQ2a2TMitIqf7TyYxRc1DPiYqks00i+tQQXdEx9yAai3rhYqQzXEMzX
a4AfCJb4MZWmdm/auTpSRPa/NzgmYfPe+xN/hRzyU6o/fGXxvJNRGAwgD5b0LJZH
2SeEOJEaZY3NxPH27aF+G1YjUIiB6HWDonookrcIZoaho+1/Sd9Qr7wzgwjOEeAA
Rt9rQhRcibJWC7S8hsFDNX5mzLJkw5dxGA8OAwIDAQABAoIBADBWpIll3Gf37cvv
5G1h7jHL0Q0cD/KGpex7+lTSjQsltiM7dSzokdJqufy6duVARj/judrV0vAScRol
14oW502u9183LG85Y4YvgbyfkC8fNWsG3Zif8bTyZhrtWxZ0x5vBEVdnYq054Uxj
XwdXAGmi1xlZs8goLyLzahUebtuPxh4391HRNdn3Aa3DzleWl6sFFzgkToJGNAfq
HAbAxiLcmavNp35HUgRC4Le2pZ8L0Vo0htH6YUxFqH+Bo/kmdSDSLEznZ/9uGUpc
3nL3EuIoyKUgNrJ5yq5A7sF1FIQdwD4vmtGzBpAJo9yNwJPaPtJ3KUANjNvHgaUn
XIz34kkCgYEA/2p6hhk2fu5wavNY/gxGPlWgvMvMpSXSxtj1godSE4SP0LOhBcx9
qz5N5uaaLPU6mflO/bq2U3Xf8LH0+9b0MzdpzTThIIJy8jPjKt8JL6Kpb/64Ad6J
awxECj0qJAiZ8d9YU5+YIH9ZHtfCJzWuv0t3kjAoyvTC3tx+JKv0LG0CgYEA5onA
aua7m4uI1AurycCrBy3ZvfhiITtVdPuBjMf6NR8J/VEqOwIQ07BFuy9IQKdtuU9d
pjom2wZUztOCJ0kUHp220w/WXzkbXZ+HMq574scOYS9XmH2d+ZX+zxLxaai/Qt+n
KS5o1jytc4UJ+rmk6jQrWBPfi5Lb9igPgjUKvi8CgYA96YOVqdrp3cZmRmKWAkes
qHj0CrqqdYaoKMMqRr8AeCucPU6U50K3Fb0wcUmCCFeSJzqcinvTs0j7QUfPHAXJ
vG7rDRxdEwHl7+nq5HGHmHhV63qTCWxqBGkhyj3Cykr2tFrmulLX3caukUJA2uRm
/lYXm5Dn0XjDKNNy9DOV6QKBgDdjrWmB2l163vsjerjUo8Lrzz8HaHxXhya+Ltgm
TAVrWbkVQTJAQs65sWdR6ugt0f0OBpAjtKY3FTVEOCc8NatNdVmsmnLyg5Kw+4i/
x2ArN1c+SquGsuf+k+Qoxvv94UYt+jm4vtOKbJouwsEMzYS/2BInZDRiqpqv8Vn1
aIldAoGBAM+kE1WgnhgPN8tK/8TEFAfR6QH9p2dKRI+qAHjctDo4frQzpRzJs5zd
CuWb/rpKmc5PEOlRH51izH25BUQjlei43O95ZFT6lrs4iOXPXRoXi+eV1RyUener
VHFxVmACJ+LkGXkCA9AYMidtgb1Kti2z09rtV2Tvs1//g5kbMIQi
-----END RSA PRIVATE KEY-----" > /home/commercial/.ssh/id_rsa
chmod 600 /home/commercial/.ssh/id_rsa
chown -R 1001:1001 /home/commercial
