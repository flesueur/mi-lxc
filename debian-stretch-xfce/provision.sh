#!/bin/bash

while [ ! `ip addr show dev eth0 | grep "inet "` ]
do
echo Waiting for IP
sleep 1
done


apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
DEBIAN_FRONTEND=noninteractive apt-get install -y xnest apache2 vim xfce4 firefox-esr tcpdump dsniff whois wireshark net-tools # keyboard-configuration  wireshark firmware-atheros firmware-misc-nonfree
apt-get clean
