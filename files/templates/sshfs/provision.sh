#!/bin/bash
# Internal template

if [ -z `hostname | grep lxc-infra` ] ; then exit 1; fi

DEBIAN_FRONTEND=noninteractive apt-get install -y sshfs libpam-mount

echo -e "#!/bin/bash\nmknod -m 666 /dev/fuse c 10 229\nexit 0" > /etc/rc.local
chmod +x /etc/rc.local

echo "user_allow_other" >> /etc/fuse.conf

cp /mnt/lxc/templates/sshfs/pam_mount.conf.xml /etc/security/

# avec clés SSH
