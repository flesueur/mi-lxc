# Current list of AS

* NS ROOT O (ASN 5, 10.10.0.0/24) is a root DNS nameserver
* NS ROOT P (ASN 6, 10.10.1.0/24) is a root DNS nameserver
* OpenDNS (ASN 7, 10.10.10.0/24) is an open DNS resolver
* TLD milxc (ASN 8, 10.10.20.0/24) is the TLD operator for .milxc
* Target (ASN 10, 10.100.0.0/16, target.milxc) is some cool enterprise to attack
* Ecorp (ASN 11, 10.101.0.0/16, ecorp.milxc) is some evil enterprise used to attack
* MICA (ASN 12, 10.102.0.0/16, mica.milxc) is a CA, ready for ACME (let's encrypt-style)
* Gozilla (ASN 13, 10.103.0.0/16, gozilla.milxc) is a web browser editor (ie, Mozilla), allowed to spread new root CA certificates to browsers
* ISP-A (ASN 20, 10.150.0.0/16, ispa.milxc) is some end-user ISP
* Transit-A (ASN 30, 10.180.0.0/24) is a transit operator
* Transit-B (ASN 31, 10.181.0.0/24) is a transit operator

# Details of AS

## Target

* target-dmz :
  * smtp, imap for users admin@, commercial@
  * http on www.target.milxc
  * certbot pre-installed for ACME with MICA
* target-ldap :
  * ldap server
* target-admin:
  * administrator workstation
  * claws-mail (for debian user) configured for admin@target.milxc
* target-commercial:
  * salesman workstation
  * claws-mail (for commercial user) configured for commercial@target.milxc

## Ecorp

* ecorp-router:
  * bird BGP daemon to alter BGP routing
* ecorp-infra:
  * http to serve fake/malicious content
  * certbot pre-installed for ACME
* This AS is used to impersonate Target

## MICA

* mica-infra :
  * step-cli and step-ca ready to deploy an ACME-compliant CA using step software
  * openssl for an old-style CA
  * http (allows to share the generated root certificate)

## Gozilla

* gozilla-infra :
  * addcatofox.sh root.crt to push root.crt to future browser updates


## ISP-A

* isp-a-infra:
  * smtp, imap for users hacker@
* isp-a-home:
  * updatefox.sh to simulate a browser update (and updates the root certificates from Gozilla)
* isp-a-hacker:
  * some hacking scripts in /home/hacker
  * claws-mail (for debian user) configured for hacker@ispa.milxc
