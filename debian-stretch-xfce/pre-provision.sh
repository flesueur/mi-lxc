#!/bin/bash

while [ ! `ip addr show dev eth0 | grep "inet "` ]
do
echo Waiting for IP
sleep 1
done

ssh-keygen -f /root/.ssh/id_rsa -N ""
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server
ssh -o "NoHostAuthenticationForLocalhost True" localhost /tmp/lxc/provision.sh

