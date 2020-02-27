#!/bin/sh
# BGP router template
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

#sed -i "s/dhcp/manual/" /etc/network/interfaces

echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
apk update
apk add dynamips screen

mkdir /root/dynamips
cp bins/*.bin /root/dynamips/
rc-update add local default
#echo -e "#!/bin/sh\nscreen -S dynamips -d -m dynamips /root/dynamips/c7200-p-mz.124-10.bin  -t npe-400 -p 0:PA-8E -s 0:0:linux_eth:eth0 -s 0:1:linux_eth:eth1" > /etc/local.d/dynamips.start
cp dynamips.sh /root/
chmod +x /root/dynamips.sh
echo -e "#!/bin/sh\nscreen -S dynamips -d -m /root/dynamips.sh" > /etc/local.d/dynamips.start
chmod +x /etc/local.d/dynamips.start
