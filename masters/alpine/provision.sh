#!/bin/sh

#while [ ! `ip addr show dev eth0 | grep "inet "` ]
#do
#echo Waiting for IP
#sleep 1
#done
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

apk update
apk upgrade
