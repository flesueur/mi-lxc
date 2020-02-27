#!/bin/sh

IFACES=`ls /sys/class/net | grep eth`
DEVS=""
INDEX="0"

for i in $IFACES
do
	DEVS="$DEVS -s 0:$INDEX:linux_eth:$i"
	INDEX=$((INDEX+1))
done

echo $DEVS

dynamips /root/dynamips/c7200-p-mz.124-10.bin  -t npe-400 -p 0:PA-8E $DEVS
