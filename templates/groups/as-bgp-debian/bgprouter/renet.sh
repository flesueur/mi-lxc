#!/bin/bash
# BGP router template
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

sed -i "s/router id/router id $asn; #/" /etc/bird/bird.conf
sed -i "s/^protocol direct.*$//" /etc/bird/bird.conf
if [ ! -z $asdev ]
 then
 IFS=';'
 for i in $asdev; do
   echo "protocol direct {   interface \"$i\"; } " >> /etc/bird/bird.conf
 done
fi

# service bird restart
