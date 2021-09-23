#!/bin/bash
# https://www.blog-libre.org/2016/01/09/installation-et-configuration-de-apt-cacher-ng/
# https://askubuntu.com/questions/53443/how-do-i-ignore-a-proxy-if-not-available

proxy=$(/sbin/ip route | awk '/default/ { print $3 }' | head -1)

### Détection du proxy et affichage du résultat sur la sortie standard ###
nc -zw1 $proxy 3142 && echo http://$proxy:3142/ || echo DIRECT
