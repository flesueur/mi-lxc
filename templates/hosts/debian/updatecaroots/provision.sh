#!/bin/bash
# Template to update CA roots
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

# Add to system store
cp updatefox.sh /usr/local/sbin/
chmod a+x /usr/local/sbin/updatefox.sh
#echo "* * * * * root /usr/local/sbin/updateca.sh" > /etc/cron.d/updateca

# Add to Firefox store
echo -e '{
 "policies": {
   "Certificates": {
      "ImportEnterpriseRoots": true,
      "Install": ["/etc/ssl/certs/root.pem"]
   }
 }
}' > /usr/lib/firefox-esr/distribution/policies.json


# cp root.crt /usr/local/share/ca-certificates/
# update-ca-certificates

# https://wiki.mozilla.org/CA/AddRootToFirefox
# cert dans /usr/lib/mozilla/certificates
# /usr/lib/firefox-esr/distribution/policies.json
# {
# "policies": {
#   "ImportEnterpriseRoots": true
# }
# }
#{
# "policies": {
#   "ImportEnterpriseRoots": true,
#   "BlockAboutConfig": true,
#   "Certificates": {
#      "ImportEnterpriseRoots": true,
#      "Install": ["/etc/ssl/certs/root.pem"]
#   }
# }
#}
