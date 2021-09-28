#!/bin/bash
# Target admin
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

# systemctl set-default graphical.target

# DEBIAN_FRONTEND=noninteractive apt-get install -y thunderbird


#cp -ar /mnt/lxc/commercial/homedir/* /home/debian/
#ln -sf /home/debian/background.jpg /usr/share/images/desktop-base/default
mkdir -p /home/admin/.ssh

echo -e "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAw3eBHMQxKhK57cfV4Yq2tzpEWOPsG2R7TNNx1uipoYY4KSGb
j1HJUq4obevv/IbQcajXeh+NWmZZWPXOoourB0bC49J/f/5llci0GYSGrccpxRJp
w3HiY6fsLjLfrkubi138OaMd01WEt68A4Gi3JFqkWoj8v3s5Kvc5PsxB6NBXpobV
uwutTioxSAGug4Q6GnWVqtU9jYnnrpGe/vgrVf34F647DM5fI31fU/ndBqge/yt3
Q8zkwROTmvZ/go6QnNdydqcZt34ewWUpR5WxuTICD1dGJmm6O66oG9ALZv38RH+L
mdWzaxGguosT9m/uYDhWHTnunJXEDREqhZSd/QIDAQABAoIBAEjRmXD9Cg/RgCC8
RMrMYXtrIpE2//vIeELLtupILQG2ve9czNYcsvKxXPBuaC5cjwT40KV3YbKe1IRW
to9JlwKT8wDqp4MoY/HkHmwvOfk9bCs1y97660sTAOLJIxmMozrNXayfPvo/Lr07
Xgk8GZZaikYMKJSxND/0cAgcEiXH6DsWjGtcDoG+2w3FzZbgHdkNJ3oa5p4QTXI3
FgUFAwxCphG5q5e0mz31ixZbXVmQqUPzjOe7pKVAslhij6u1bHJam1yE5lJ0BCwP
CU7U9PnvilUsb5IKxoMIa9UwaRgE3GRrOGLEfaTZvu6DyuSwS10+y50XMLblwilW
U0bVjMUCgYEA+6dBGI99+xtGfDS/aAj0TJ9iFrt3BDot8kY6AGxkIAJTs6+/B1Kf
b5ErXGc1Df7c8/tuqHQSr/pukKU+SO/iSEGxQr5+zZCpfo1JzQ5krug3qRV6Ez22
UG3Qf6UNL4hCmixTGjF3x/iTPGjYVcJmYUKNFWqzdlKlMpjNPlbM9M8CgYEAxtfO
zwcUl3PlF+9hJqCrSW+Cwsslzhz7pTBtwxTbyMtbz/OiLwv/na97fbLv8tQETfS0
FeYxFc2lLE2BBIYEI0g7pyVxjMI9sWjDHJQjf1TAoiKnjvclYiGCnJ/x8hWCCNG0
oP2IaZ0s7vQr9b05yzcKtoBllv/gbjubmu4WS3MCgYA/YILzZYfrypW4yCwATmkA
Nw+j+/hgVyqlHmyTGLkqmotr8HHirTs8BMpvzgo9iRcqVwMqZ3khWqenxAXopolN
e0XiMkmLCci1921DuEFBD3idG6yP1fXpUY615uJoOx/S5iDTsuugsAicqSb6iifw
jKstXp7tyKiUEol2DrQ1XwKBgQCvlkJ5brcwRpc225vekGKxJldBzEJGEDHnXSyP
6Ats9KbOq0W8ZcwDYsKZ7TkWJULn0/5ymCMgLch9prMXW4Cr501F/DqZIa14zBn/
UpFGD4FLq25rQLMyRIUh6dus+nEpeIUY5Mlg+fqDx/pJth8i5CgBoMAU5z84GEsA
NN5bIQKBgB7UV8UgXIV54fy9DPQS70vNRNzOawNS1IvrlbZ64MUZiZkdO5E1LufK
3YNbjTwYGcrSszwlqFCftf2zJ+mEMSZY2BEcmpWSert4cOjUEOSxfpww9mXn7PD+
BBp9fHDQ/VFmP35vkh0a2HvSMcr9ISbW59LJrSzHJVY7HLrSB+wl
-----END RSA PRIVATE KEY-----" > /home/admin/.ssh/id_rsa
chmod 600 /home/admin/.ssh/id_rsa

chown -R 1003:1001 /home/admin
