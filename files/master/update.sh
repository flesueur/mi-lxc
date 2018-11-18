#!/bin/bash

#while [ ! `ip addr show dev eth0 | grep "inet "` ]
#do
#echo Waiting for IP
#sleep 1
#done

if [ -z `hostname | grep lxc-infra` ] ; then exit 1; fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y autoremove
apt-get clean
