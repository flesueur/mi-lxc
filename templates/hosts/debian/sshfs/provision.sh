#!/bin/bash
# sshfs template
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y sshfs libpam-mount hxtools

echo -e "#!/bin/bash\nmknod -m 666 /dev/fuse c 10 229\nexit 0" > /etc/rc.local
chmod +x /etc/rc.local

echo "user_allow_other" >> /etc/fuse.conf

cp pam_mount.conf.xml /etc/security/
sed -i -e "s/\$server/$server/" /etc/security/pam_mount.conf.xml




# avec clés SSH
