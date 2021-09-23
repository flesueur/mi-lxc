# Liste actuelle des AS

* NS ROOT O (ASN 5, 100.100.0.0/24) est un serveur DNS root
* NS ROOT P (ASN 6, 100.100.1.0/24) est un serveur DNS root
* OpenDNS (ASN 7, 100.100.100.0/24) est un résolveur openDNS
* TLD milxc (ASN 8, 100.100.20.0/24) est l'opérateur TLD pour .milxc
* La cible (ASN 10, 100.80.0.0/16, target.milxc) est une entreprise intéressante à attaquer
* Ecorp (ASN 11, 100.81.0.0/16, ecorp.milxc) est une entreprise maléfique utilisée pour attaquer
* MICA (ASN 12, 100.82.0.0/16, mica.milxc) est un CA, prêt pour ACME (du style à let's encrypt)
* Gozilla (ASN 13, 100.83.0.0/16, gozilla.milxc) est un éditeur de navigateur web (ie, Mozilla), autorisé à diffuser de nouveaux certificats d'AC racine aux navigateurs
* ISP-A (ASN 20, 100.120.0.0/16, ispa.milxc) est un ISP d'utilisateur final
* Transit-A (ASN 30, 100.64.0.0/24) est un opérateur de transit
* Transit-B (ASN 31, 100.64.1.0/24) est un opérateur de transit

# Détails des AS

## Target

* target-router
  * pare-feu pour Target
  * suricata, prelude et prewikka sont préinstallés
* target-dmz :
  * smtp, imap pour users admin@, commercial@
  * http sur www.target.milxc (mot de passe faible)
  * certbot préinstallé pour ACME avec MICA
  * OSSEC HIDS
  * instance MISP écoutant sur misp.target.milxc (admin@admin.test/admin)
* target-ldap :
  * serveur ldap
  * tous les hôtes s’appuient simplement sur cette authentification centralisée (chaque utilisateur peut ainsi se connecter à n’importe quel hôte interne)
* target-filer :
  * partage de fichiers sshfs de /home/shared/ (NFS ne fonctionne pas sur la configuration actuelle)
  * les partages réseau sont montés dans ~/partagés sur target-admin, target-commercial et target-dev
* target-intranet :
  * aun intranet web avec des injections SQL et quelques droits d’accès de mauvaise qualité dans /var/www
* target-admin:
  * poste de travail administrateur
  * claws-mail (pour l’utilisateur debian) configuré pour admin@target.milxc
* target-commercial:
  * poste de travail du vendeur
  * claws-mail (pour l’utilisateur commercial) configuré pour commercial@target.milxc
* target-dev:
  * poste de travail du développeur
  * peut déployer du code sur target-intranet (dans ~/shared/dev/deploy.sh)

## Ecorp

* ecorp-router:
  * daemon de bird BGP pour modifier le routage BGP
* ecorp-infra:
  * http pour exposer du contenu faux/malveillant
  * certbot préinstallé for ACME
* Cette AS est utilisée pour usurper l’identité de la cible

## MICA

* mica-infra :
  * step-cli et step-ca prêts à déployer un CA compatible ACME à l’aide de la suite logicielle Smallstep
  * openssl pour un CA à l'ancienne
  * http (permet de partager le certificat root généré)

## Gozilla

* gozilla-infra :
  * addcatofox.sh root.crt pour pousser root.crt vers les futures mises à jour du navigateur
  * instance MISP écoutant sur misp.gozilla.milxc (admin@admin.test/admin)



## ISP-A

* isp-a-infra:
  * smsmtp, imap pour l’utilisateur hacker@ispa.milxc
* isp-a-home:
  * updatefox.sh pour simuler une mise à jour du navigateur (et mettre à jour les certificats root de Gozilla)
* isp-a-hacker:
  * quelques scripts de piratage dans /home/hacker
  * claws-mail (pour l’utilisateur debian) configuré pour hacker@ispa.milxc
