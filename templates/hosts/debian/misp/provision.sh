#!/bin/bash
# MISP server template
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server git debhelper dh-apache2 sudo libapache2-mod-php ca-certificates python3 python3-setuptools python3-wheel composer mariadb-client openssl zip unzip moreutils php-mysql php-pear php-redis php-gd php-gnupg php-json php-xml php-readline php-mbstring php7.3-opcache libfuzzy-dev

cd /tmp
git clone --branch v2.4.128 https://github.com/MISP/MISP.git
#mv MISP misp-2.4.220
#cd misp-2.4.220
cd MISP
git submodule init
git submodule update

sed -i -e 's/mysql -h$HOST -uroot -p$ROOTPWD/mysql -uroot/' debian/postinst
sed -i -e 's/mysql -h$HOST -u$MISPDBUSER -p$MISPDBUSERPWD/mysql -u$MISPDBUSER -p$MISPDBUSERPWD/' debian/postinst
sed -i -e "s/'change_pw' => 1/'change_pw' => 0/" app/Model/User.php
sed -i -e "s/ServerName misp.local/ServerName $hostname/" debian/misp.apache2.conf

./build-deb.sh

cd ..

echo -e "misp misp/mariadb_rootpwd  password root
misp  misp/mariadb_setmisppwd  password misp
misp  misp/base_url string http://$hostname
misp  misp/mariadb_mispdb string misp
misp  misp/configure_mariadb  select  Yes
misp  misp/mariadb_host string 127.0.0.1
misp  misp/mariadb_mispdbuser string misp" | debconf-set-selections

#DEBIAN_FRONTEND=noninteractive apt-get -f install -y libapache2-mod-php ca-certificates python3 python3-setuptools python3-wheel composer mariadb-client openssl zip unzip moreutils php-mysql php-pear php-redis php-gd php-gnupg php-json php-xml php-readline php-mbstring php7.3-opcache libfuzzy-dev
#DEBIAN_FRONTEND=noninteractive dpkg -i misp_2.4.125-1_all.deb
DEBIAN_FRONTEND=noninteractive dpkg -i misp*.deb

# Re-enable default site
a2ensite 000-default

#DEBIAN_FRONTEND=noninteractive apt-get -f install -y

#sed -i -e 's/http:\/\/127.0.0.1/http:\/\/filer.target.milxc/' /usr/share/misp/app/Config/config.php
# default credentials : admin@admin.test / admin
