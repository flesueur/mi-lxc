#!/bin/bash
# Mail client template
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

# $domain, $mailname, $password

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y claws-mail

if [ -z $login ] ; then
  login="debian"
fi

cp -ar claws-mail /home/$login/.claws-mail
#chown -R $login /home/$login/.claws-mail
chmod -R 777 /home/$login/.claws-mail

sed -i -e "s/\$domainname/$domain/" /home/$login/.claws-mail/accountrc
sed -i -e "s/\$mailname/$mailname/" /home/$login/.claws-mail/accountrc

sed -i -e "s/\$domainname/$domain/" /home/$login/.claws-mail/folderlist.xml
sed -i -e "s/\$mailname/$mailname/" /home/$login/.claws-mail/folderlist.xml

# Ugly hack for now with precomputed passwords ! They could(should !) be generated on the fly on future versions, some docs :
# https://github.com/AlessandroZ/LaZagne/blob/master/Linux/lazagne/softwares/mails/clawsmail.py
# https://github.com/eworm-de/claws-mail/blob/master/doc/src/password_encryption.txt
# https://github.com/eworm-de/claws-mail/blob/aca15d9a473bdfdeef4a572b112ff3679d745247/src/password.c#L409
# For now, they have to be extracted from a configured claws in .claws-mail/passwordstorerc
# if [ "$password" = "hacker" ] ; then
#   pass="AiU2DSaWBrjobby90aPWqUKtfV6bnpueNcmHKo5+59gXxh9Y1nrxFNpzOaXa/kKdoUEuyoMzCnwK9eXCS9I96u8mDzYQMall1RkJNb8hWxXOiIOI7kp4ivU+bFqRCzBBadtwdFRtvpDiQYhCIb0di3ltNLE017eoMi6sRrd23PY="
# elif [ "$password" = "commercial" ] ; then
#   pass="jcFj1Y73ajScjfy2OL6ld76+Xb/pM28UWQJIgBKbIS8X5vRnSRUL7KBExMhpkAxBpunE10kuWwu0ojXxn5Pey1BJ7EnNnEHi0jsc+dM5RkBlC3NkwkdOetkzMvahDkHZ6qfp7iUGhEBLSq+DlR2ePzjuDTUAlVu14AADfUaNUe8="
# else
#   pass="EncryptedPassword"
# fi
#{AES-256-CBC,50000}

# chmod +x genpasswd
pass=`./genpasswd $password`
#gcc genpasswd.c -o genpasswd -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include -I/usr/lib/x86_64-linux-gnu/glib-2.0/include/ -lglib-2.0 -lgnutls

sed -i -e "s;\$password;$pass;" /home/$login/.claws-mail/passwordstorerc
# AiU2DSaWBrjobby90aPWqUKtfV6bnpueNcmHKo5+59gXxh9Y1nrxFNpzOaXa/kKdoUEuyoMzCnwK9eXCS9I96u8mDzYQMall1RkJNb8hWxXOiIOI7kp4ivU+bFqRCzBBadtwdFRtvpDiQYhCIb0di3ltNLE017eoMi6sRrd23PY=
