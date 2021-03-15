# Tutoriel MI-LXC


I-Déroulement de ce tutoriel
=============================

MI-LXC est un framework permettant de concevoir des architectures réseaux/systèmes dans lesquelles des apprenants peuvent se confronter à un environnement réaliste. Ce tutoriel est ainsi découpé en 3 parties correspondant aux différentes facettes de MI-LXC :

* **Apprenant - L'apprentissage du fonctionnement d'internet et des problèmes de sécurité**. Il s'agit d'utiliser une infrastructure préalablement spécifiée (topologie, logiciels installés et configurés sur l'ensemble des conteneurs). Sur cette infrastructure, il pourra découvrir le fonctionnement d'internet, les interconnexions systèmes entre les différents AS, les schémas d'attaque et de défense. Dans cette posture, il s'agit de lancer MI-LXC (`./mi-lxc.py start`) puis de se connecter à différents conteneurs de cette infrastructure (`./mi-lxc.py display isp-a-hacker`, `./mi-lxc.py attach target-dmz`, etc.)
* **Concepteur - La spécification d'une infrastructure**. Il s'agit de spécifier une infrastructure :
  * La topologie (noms des hôtes, adresses IPv4/IPv6, bridges réseaux) (`global.json` et `groups/*/local.json` pour chaque AS)
  * L'installation et la configuration de chaque système (scripts bash `provision.sh` pour chaque hôte groups/\*/\*/provision.sh)
  * La mise en place de templates pour mutualiser les aspects communs (scripts bash `provision.sh` pour des templates d'hôtes et `local.json` pour des templates d'AS, dans le dossier `templates`)
  * La création de masters pour utiliser d'autres distributions (dossier `masters`)
* **Développeur - Le développement du moteur de MI-LXC**. Il s'agit de proposer de nouvelles fonctionnalités dans le framework MI-LXC, dans le code python `mi-lxc.py` ainsi que le dossier `backends/`. Par exemple, l'amélioration de la visualisation, de la gestion de configuration ou le support d'autres backends d'hôtes que LXC (Linux uniquement) ou Dynamips (routeurs cisco), par exemple ajouter Vagrant/Virtualbox pour pouvoir générer des machines Windows.


II-Avant de démarrer
===================

1. Une [présentation générale](https://www.sstic.org/2020/presentation/mi-lxc_une_plateforme_pedagogique_pour_la_securite_reseau/) à SSTIC 2020 (slides + vidéo)
2. Un [tutoriel vidéo](https://mi-lxc.citi-lab.fr/data/media/tuto1.mp4) de démarrage
3. Une installation fonctionnelle :
  * Une VM VirtualBox prête à l'emploi (environ 5GO à télécharger puis une VM de 11GO) : [ici](https://mi-lxc.citi-lab.fr/data/milxc-debian-amd64-1.3.1.ova). Il faut s'y connecter en root/root puis, avec un terminal :
    * `cd mi-lxc`
    * `./mi-lxc.py start`
    * `./mi-lxc.py display isp-a-hacker`
  * La création de la VM via Vagrant (VM d'environ 11GO, 15-30 minutes pour la création) : [ici](INSTALL.md#installation-on-windowsmacoslinux-using-vagrant). Les conteneurs LXC sont automatiquement générés lors de la création de la VM. Une fois Vagrant fini, il faut ensuite se connecter à la VM en root/root puis, avec un terminal :
    * `cd mi-lxc`
    * `./mi-lxc.py start`
    * `./mi-lxc.py display isp-a-hacker`
  * L'installation directe sous Linux (15-30 minutes pour la création) : [ici](INSTALL.md#installation-on-linux). Les conteneurs LXC seront installés sur l'hôte :
    * `git clone https://github.com/flesueur/mi-lxc.git`
    * `cd mi-lxc`
    * `./mi-lxc.py create`
    * `./mi-lxc.py start`
    * `./mi-lxc.py display isp-a-hacker`



III-Apprenant - L'apprentissage du fonctionnement d'internet et des problèmes de sécurité
=========================================================================================

Nous allons voir 2 aspects côté apprenant :
* Une attaque BGP
* Une segmentation réseau (redécoupage)

Ces 2 éléments permettent un premier aperçu des fonctionnalités de MI-LXC et peuvent être complétés avec les sujets de TP cités en début de README.

III.1-Attaque BGP
-----------------

(Extrait de [TP CA](https://github.com/flesueur/csc/blob/master/tp1-https.md))

Vous pouvez afficher un plan de réseau avec `./mi-lxc.py print`.

Pour vous connecter à une machine :

* `./mi-lxc.py display isp-a-home` : pour afficher le bureau de la machine isp-a-home qui vous servira de navigateur web dans ce TP (en tant qu'utilisateur debian)
* `./mi-lxc.py attach target-dmz` : pour obtenir un shell sur la machine target-dmz qui héberge le serveur web à sécuriser (en tant qu'utilisateur root)

Toutes les machines ont les deux comptes suivants : debian/debian et root/root (login/mot de passe).

Depuis la machine isp-a-home, ouvrez un navigateur pour vous connecter à `http://www.target.milxc`. Vous accédez à une page Dokuwiki, qui est bien la page attendue.

Nous allons maintenant attaquer depuis l'AS ecorp cette communication en clair, non sécurisée, entre isp-a-home et target-dmz. L'objectif est que le navigateur, lorsqu'il souhaite se connecter à l'URL `http://www.target.milxc`, arrive en fait sur la machine ecorp-infra. Cette attaque BGP consiste donc à dérouter les paquets à destination de l'AS target vers l'AS ecorp (un [exemple de BGP hijacking réel en 2020](https://radar.qrator.net/blog/as1221-hijacking-266asns)) :
* Sur la machine ecorp-router : prendre une IP de l'AS target qui déclenchera l'annonce du réseau en BGP (`ifconfig eth1:0 100.80.1.1 netmask 255.255.255.0`)
* Sur la machine ecorp-infra : prendre l'IP de `www.target.milxc` (`ifconfig eth0:0 100.80.1.2 netmask 255.255.255.0`)

Nous constatons ainsi un cas d'attaque BGP : un utilisateur sur isp-a-home qui, en tapant l'URL `www.target.milxc`, arrive en fait sur un autre service que celui attendu. Remettez le système en bon ordre de marche pour continuer (désactivez l'interface eth1:0 sur ecorp-router `ifconfig eth1:0 down`).

III.2-Segmentation réseau
-------------------------

(Extrait de [TP Firewall](https://github.com/flesueur/srs/blob/master/tp2-firewall.md))

Nous allons segmenter le réseau target pour y déployer un firewall entre des zones distinctes. La segmentation aura lieu autour de la machine "target-router". Vous aurez besoin de procéder en deux étapes :

* Segmenter le réseau "target" (**Prenez le temps de regarder le [tuto vidéo](https://mi-lxc.citi-lab.fr/data/media/segmentation_milxc.mp4) !!!**) :
	* Éditer `global.json` (dans le dossier mi-lxc) pour spécifier les interfaces sur le routeur, dans la section "target". Il faut ajouter des bridges (dont le nom doit commencer par "target-") et découper l'espace 100.80.0.1/16. Enfin, il faut ajouter les interfaces eth2, eth3... ainsi créées à la liste des `asdev` definie juste au-dessus (avec des ';' de séparation entre interfaces)
	* Éditer `groups/target/local.json` pour modifier les adresses des interfaces et les bridges des machines internes (attention, pour un bridge nommé précédemment "target-dmz", il faut simplement écrire "dmz" ici, la partie "target-" est ajoutée automatiquement). Dans le même fichier vous devrez aussi mettre à jour les serveurs mentionnés dans les paramètres des templates "ldapclient", "sshfs" et "nodhcp", soit en remplaçant les noms de serveurs par leurs nouvelles adresses IP, soit en mettant à jour les enregistrements DNS correspondants (fichier `/etc/nsd/target.milxc.zone` sur "target-dmz")
	* Exécuter `./mi-lxc.py print` pour visualiser la topologie redéfinie
	* Exécuter `./mi-lxc.py stop && ./mi-lxc.py renet && ./mi-lxc.py start` pour mettre à jour l'infrastructure déployée
* (Étape non nécessaire pour réaliser le tutoriel) Implémenter de manière adaptée les commandes iptables sur la machine "target-router" (dans la chaîne FORWARD). Si possible dans un script (qui nettoie les règles au début), en cas d'erreur.

> L'arborescence de MI-LXC et les fichiers json manipulés ici sont décrits [ici](https://github.com/flesueur/mi-lxc#how-to-extend).


IV-Concepteur - La spécification d'une infrastructure
=====================================================

L'idée générale n'est, a priori, pas de repartir from scratch mais d'enrichir une infrastructure de base (actuellement, un mix infra de base + usagers). L'infra de base, c'est typiquement le backbone + les services DNS.

On va ajouter un AS ACME. Il faut :
* Lui attribuer un numéro d'AS + plage d'IP : MI-IANA.txt
* Lui faire utiliser le template d'AS : global.json
* Faire un create : on voit déjà qu'un conteneur s'ajoute, router : template d'AS
* Créer le dossier + local.json
* Faire la base du JSON
* Créer un hôte supplémentaire :
  * son provision.sh : shebang, garde MI-LXC, installer des packages, configurer. Favoriser les modifs aux remplacements de fichiers (donc sed concat etc.)
  * Faire un create, voir le nouveau conteneur
  * maintenant on ajoute un fichier à copier : destroy spécifique puis create (gaffe à la boulette du destroy global !). Snapshot de VM avant ?
  * templates : spécifier que c'est un client mail, destroy puis create
  * faire un template et l'utiliser (ajouter un greeting dans le .bashrc ?)


V-Développeur - Le développement du moteur de MI-LXC
====================================================

On va regarder comment ajouter un backend de virtualisation (autre que LXC) :
* on crée un nouveau master avec un autre backend
* on remonte les erreurs
* le switch de mi-lxc.py, on le résout
* puis on crée le backend depuis l'interface
