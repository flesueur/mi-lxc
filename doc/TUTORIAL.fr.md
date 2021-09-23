# Tutoriel MI-LXC

[![en](https://img.shields.io/badge/lang-en-informational)](https://github.com/flesueur/mi-lxc/blob/master/doc/TUTORIAL.md)

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

> Pour sortir une souris coincée dans un Xephyr, Ctrl+Shift



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

Depuis la machine isp-a-home, ouvrez un navigateur pour vous connecter à `http://www.target.milxc`. Vous accédez à une page Dokuwiki, qui est bien la page attendue hébergée sur target-dmz.

Nous allons maintenant attaquer depuis l'AS ecorp cette communication en clair, non sécurisée, entre isp-a-home et target-dmz. L'objectif est que le navigateur, lorsqu'il souhaite se connecter à l'URL `http://www.target.milxc`, arrive en fait sur la machine ecorp-infra. Cette attaque BGP consiste donc à dérouter les paquets à destination de l'AS target vers l'AS ecorp (un [exemple de BGP hijacking réel en 2020](https://radar.qrator.net/blog/as1221-hijacking-266asns)) :
* Sur la machine ecorp-router : prendre une IP de l'AS target, ce qui déclenchera automatiquement l'annonce de ce réseau en BGP (`ifconfig eth1:0 100.80.1.1 netmask 255.255.255.0`)
* Sur la machine ecorp-infra : prendre l'IP de `www.target.milxc` (`ifconfig eth0:0 100.80.1.2 netmask 255.255.255.0`)

Nous constatons ainsi un cas d'attaque BGP : un utilisateur sur isp-a-home qui, en tapant l'URL `www.target.milxc`, arrive en fait sur un autre service que celui attendu (ici, la machine ecorp-infra). Remettez le système en bon ordre de marche pour continuer (désactivez l'interface eth1:0 sur ecorp-router `ifconfig eth1:0 down`).

> Le site [Is BGP safe yet?](https://isbgpsafeyet.com/), opéré par Cloudflare, décrit de manière très claire ces attaques BGP, et donne une synthèse de l'état actuel de la sécurité de BGP et du déploiement de RPKI, contre-mesure à ces attaques BGP.

III.2-Segmentation réseau
-------------------------

(Extrait de [TP Firewall](https://github.com/flesueur/srs/blob/master/tp2-firewall.md))

Nous allons segmenter le réseau target pour y déployer un firewall entre des zones distinctes. La segmentation aura lieu autour de la machine "target-router". Au départ, le réseau interne est totalement à plat, connecté au bridge target-lan et dans l'espace d'adressage 100.80.0.1/16. Nous allons simplement rajouter une DMZ sur ce réseau à plat (un nouveau bridge réseau et un redécoupage de l'espace d'adressage). Vous aurez besoin de procéder en deux étapes :

* Segmenter le réseau "target" (**Prenez le temps de regarder le [tuto vidéo](https://mi-lxc.citi-lab.fr/data/media/segmentation_milxc.mp4) !!!**) :
	* Éditer `global.json` (dans le dossier mi-lxc) pour spécifier les interfaces sur le routeur, dans la section "target". Il faut ajouter un bridge target-dmz (le nom doit commencer par "target-") et découper l'espace 100.80.0.0/16 : 100.80.0.0/24 sur le bridge target-lan pré-existant (donc spécifier une IPv4 de 100.80.0.1/24), 100.80.1.0/24 sur le nouveau bridge target-dmz (donc spécifier une IPv4 de 100.80.1.1/24). Enfin, il faut ajouter l'interface eth2 ainsi créée à la liste des `asdev` definie juste au-dessus (avec des ';' de séparation entre interfaces, il y a des exemples autour)
	* Éditer `groups/target/local.json` pour modifier les adresses des interfaces et les bridges des machines internes (attention, pour un bridge nommé précédemment "target-dmz", il faut simplement écrire "dmz" ici, la partie "target-" est ajoutée automatiquement). Il faut :
      * Passer la machine dmz sur le bridge dmz, passer son adresse à 100.80.1.2/24, mettre à jour sa gatewayv4 (100.80.1.1) juste en-dessous
      * Pour toutes les autres machines, mettre à jour le netmask en /24
	* Exécuter `./mi-lxc.py print` pour visualiser la topologie redéfinie
	* Exécuter `./mi-lxc.py stop && ./mi-lxc.py renet && ./mi-lxc.py start` pour mettre à jour l'infrastructure déployée
* Implémenter de manière adaptée les commandes iptables sur la machine "target-router" (dans la chaîne FORWARD) pour autoriser les routages nécessaires entre les interfaces (eth0 est l'interface de sortie, eth1 est sur le bridge target-lan et eth2 est la nouvelle interface sur le bridge target-dmz). Si possible dans un script (qui nettoie les règles au début), en cas d'erreur.

> `renet` est une opération rapide qui évite de devoir supprimer et re-générer l'infrastructure. Elle met à jour les IP et certaines configurations. Typiquement, nous verrons le script provision.sh dans la suite, renet exécute à la place le script renet.sh (présent dans certains répertoires).

> L'arborescence de MI-LXC et les fichiers json manipulés ici sont décrits [ici](https://github.com/flesueur/mi-lxc#how-to-extend).


IV-Concepteur - La spécification d'une infrastructure
=====================================================

MI-LXC permet le prototypage rapide d'une infrastructure. A priori, l'idée est d'enrichir le cœur existant plutôt que de repartir from scratch. Typiquement, le backbone, l'infrastructure DNS et un minimum de services d'accès ont vocation à justement permettre le bootstrap rapide d'un nouvel AS (donc au minimum les groupes transit-a, transit-b, isp-a, root-o, root-p, opendns, milxc, décrits dans DETAILS.md). Dans ce tutorial, nous allons ainsi ajouter un AS à l'infrastructure existante.

Le déroulement va être le suivant :
* Déclarer un numéro d'AS, une plage d'adresses IP et un nom de domaine pour cette nouvelle organisation
* Créer cet AS minimaliste dans MI-LXC
* Ajouter un autre hôte à cet AS
* Modifier ce nouvel hôte
* L'enregistrer dans le DNS
* Explorer le mécanisme des templates

IV.1-Déclaration d'un nouvel AS
-------------------------------

Le fichier `doc/MI-IANA.fr.txt` représente l'annuaire de l'IANA. Vous pouvez y trouver un numéro d'AS libre ainsi qu'une plage d'IP libre. Les IPv4 routables sont attribuées dans l'espace 100.64.0.0/10 (réservé au CG-NAT et donc normalement sans risque de conflit local).

Vous pouvez aussi en profiter pour prévoir un nom de domaine en .milxc


IV.2-Création de cet AS dans MI-LXC
-----------------------------------

Un AS est représenté par un groupe d'hôtes. La première étape est ainsi de déclarer ce nouveau groupe dans le fichier de topologie globale `global.json`. Ajoutez-y un groupe simple en partant d'un modèle existant. Par exemple, le groupe existant "milxc" est défini de la manière suivante :

```
"milxc": {
  "templates":[{"template":"as-bgp", "asn":"8", "asdev":"eth1", "neighbors4":"100.64.0.1 as 30","neighbors6":"2001:db8:b000::1 as 30",
  "interfaces":[
    {"bridge":"transit-a", "ipv4":"100.64.0.40/24", "ipv6":"2001:db8:b000::40/48"},
    {"bridge":"milxc-lan", "ipv4":"100.100.20.1/24", "ipv6":"2001:db8:a020::1/48"}
  ]
}]}
```

Le champ _template_ décrit le template du groupe, ici ce sera également un as-bgp. Les champs _asn, asdev, neighbors4, neighbors6_ et _interfaces_ doivent être ajustés :
* _asn_ est le numéro d'AS, tel que déclaré dans `MI-IANA.fr.txt`
* _asdev_ est l'interface réseau qui sera relié au réseau _interne_ de l'organisation (celle qui a les IP liées à l'AS, ce sera eth1 dans l'exemple)
* _neighbors4_ sont les pairs BGP4 pour le routage IPv4 (au format _IP\_du\_pair as ASN\_du\_pair_)
* _neighbors6_ sont les pairs BGP6 pour le routage IPv6 (optionnel, au format _IP\_du\_pair as ASN\_du\_pair_)
* _interfaces_ décrit les interfaces réseau du routeur de cet AS (malgré l'indentation trompeuse, c'est bien un paramètre du template as-bgp). Pour chaque interface, il faut spécifier son bridge, son ipv4 et son ipv6 (optionnelle) de manière statique ici. Dans cet exemple :
  * _transit-a_ est le bridge opéré par l'opérateur Transit-A, s'y connecter permet d'aller vers les autres AS, il faut utiliser une IP libre dans son réseau 100.64.0.40/24 et cette interface sera l'interface externe _eth0_
  * _milxc-lan_ est le bridge interne de cette organisation, on y associe une IP de son AS. Son nom doit **impérativement** commencer par le nom du groupe + "-", ici "milxc-", et ne pas être trop long (max 15 caractères, contrainte de nommage des interfaces réseau niveau noyau)

Pour intégrer votre nouvel AS, il faudra donc choisir à quel point de transit le connecter et avec quelle IP. Un `./mi-lxc.py print` vous donne une vue générale des connexions et IP utilisées (tant que le JSON est bien formé...). Il faut également déclarer ce nouveau pair de l'autre côté du tunnel BGP (ici, ce routeur du groupe "milxc" est par exemple listé dans les pairs BGP du groupe "transit-a").

Une fois ceci défini, un `./mi-lxc.py print` pour vérifier la topologie, puis `./mi-lxc.py create` permet de créer la machine routeur associée à cet AS (ce sera un Alpine Linux). L'opération create est paresseuse, elle ne crée que les conteneurs non existants et sera donc rapide.

> **DANGER ZONE** On va détruire un conteneur et uniquement un. Si vous faîtes une fausse manipulation, vous risquez de détruire l'infra complète et de mettre ensuite 15 minutes à tout reconstruire, ce n'est pas le but. Donc spécifiez bien le nom du conteneur à détruire et, si vous êtes dans une VM, ça peut être le moment de faire un snapshot...

À ce moment, par contre, le pair BGP (l'autre bout du tunnel BGP mis à jour dans le JSON, par exemple le conteneur transit-a-router) ne connaît pas encore ce nouveau routeur. Il faut le détruire et le re-générer : `./mi-lxc.py destroy transit-a-router` (détruit _uniquement_ le conteneur transit-a-router) puis `./mi-lxc.py create` pour le re-générer. (à terme, un renet pourrait suffire, mais ce n'est pas implémenté actuellement pour les routeurs BGP AlpineLinux)

On peut enfin faire un `./mi-lxc.py start` et vérifier le bon démarrage.

> Attention, pour des raisons de gestion des IP et des routes, étonnamment, il n'y a pas de façon simple pour que le routeur puisse lui-même initier des communications. C'est-à-dire que si tout fonctionne bien il sera démarré, aura de bonnes tables de routage, mais pour autant ne pourra pas ping en dehors du subnet du transitaire. C'est le comportement attendu et donc vérifier la connectivité du routeur ne peut pas se faire comme ça. On verra ensuite comment vérifier cela depuis un poste interne et nous utiliserons, sur le routeur ou ses voisins BGP, les commandes `birdc show route all`et `birdc show protocols` pour inspecter les tables de routage et vérifier l'établissement des sessions BGP.

IV.3-Ajout d'un hôte dans le nouvel AS
--------------------------------------

Nous allons maintenant ajouter un nouvel hôte dans cet AS. Si le groupe a été nommé "acme" dans global.json, il faut créer le dossier `groups/acme` pour l'accueillir. Dans ce dossier nous allons avoir :
* un fichier `local.json` qui décrit la topologie interne du groupe
* un sous-dossier pour le provisionning de chacun de ces hôtes

Un exemple de `local.json` minimal (groups/gozilla/local.json) :
```
{
  "comment":"Gozilla AS",
  "containers": {
    "infra":
        {"container":"infra",
          "interfaces":[
            {"bridge":"lan", "ipv4":"100.83.0.2/16", "ipv6":"2001:db8:83::2/48"}
          ],
          "gatewayv4":"100.83.0.1",
          "gatewayv6":"2001:db8:83::1",
          "templates":[{"template":"nodhcp", "domain":"gozilla.milxc", "ns":"100.100.100.100"}]}
  }
}
```

Ce JSON définit :
* qu'il y a un conteneur qui s'appelle infra (et qui sera donc provisionné dans le sous-dossier infra)
* qu'il a une interface réseau branchée sur le bridge _gozilla-lan_ avec les IP spécifiées (le préfixe _groupname-_ est automatiquement ajouté au nom écrit dans ce JSON)
* que sa passerelle IPv4 est 100.83.0.1
* qu'il utilise un template (nous détaillerons cela plus tard) qui désactive le DHCP et fixe le domaine et le serveur DNS

Pour provisionner ce conteneur, il faut créer le sous-dossier _infra_ et y écrire un script _provision.sh_ du type :
```
#!/bin/bash
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

# do something visible
```
* Le shebang est obligatoire au début et sera utilisé (et un script python, tant qu'il s'appelle provision.sh, fonctionne probablement)
* Le `set -e` est très fortement recommandé (il permet d'arrêter le script dès qu'une commande renvoie un code d'erreur, et de retourner à son tour un code d'erreur. Sans ce `set -e`, l'exécution continue et le résultat pourra vous étonner...)
* la variable _$MILXCGUARD_ est automatiquement positionnée lors de l'exécution dans MI-LXC, la vérifier permet d'éviter qu'un script puisse s'exécuter sur sa propre machine par inadvertance (aïe !)
* En général, se positionner dans le bon répertoire aide pour la suite et évite de multiples cafouillages. Ce dossier peut contenir des fichiers à copier sur le nouveau conteneur, etc.

Par bonne pratique en terme de maintenance, il faut privilégier les modifications de fichiers (à coût de sed, >>, etc.) plutôt que l'écrasement pur et simple. Exemple de sed kivabien : `sed -i -e 's/Allow from .*/Allow from All/' /etc/apache2/conf-available/dokuwiki.conf`. On trouve également dans groups/target/ldap/provision.sh les manipulations permettant de préconfigurer (_preseed_) les installations de packages Debian.

Une fois tout ceci fait, on peut faire `./mi-lxc.py print` pour vérifier que le JSON est bien formé et que la topologie est conforme. Un `./mi-lxc.py create` créera ce conteneur, puis `./mi-lxc.py start` le lancera (inutile d'avoir stoppé les autres avant).


IV.4-Modification de cet hôte
-----------------------------

Maintenant que cet hôte est créé, nous allons le modifier. Ajoutons :
* l'utilisation d'un autre template, par exemple `mailclient` (il est défini dans templates/hosts/debian/mailclient, il suffit de le nommer mailclient dans le local.json). Ce template a 4 paramètres, vous pouvez en voir un usage dans groups/target/local.json . Configurez-le avec des valeurs fictives (mettez juste 'debian' comme valeur pour login, c'est le nom du compte Linux local qui sera configuré pour le mail et ce compte doit déjà exister. Le compte debian existe et est celui utilisé par défaut pour la commande display)
* une autre action dans le provision.sh


Pour mettre à jour ce conteneur de ces modifications sans tout reconstruire, il faut :
* `./mi-lxc.py destroy acme-monconteneur` # détruit _uniquement_ le conteneur acme-monconteneur
* `./mi-lxc.py create` # reconstruit uniquement ce conteneur manquant
* `./mi-lxc.py start` # redémarre ce nouveau conteneur
* `./mi-lxc.py display acme-monconteneur` # constatez que claws-mail a été configuré par vos paramètres



IV.5-L'enregistrer dans le DNS
-----------------------------

Cet hôte a une IP publique et vous avez prévu un nom de domaine, acme.milxc (le TLD interne est .milxc). Pour avoir une entrée DNS fonctionnelle pour acme.milxc il faudra évidemment mettre en place un serveur DNS pour cette zone (exemple dans groups/isp-a/infra), ce que nous ne ferons pas ici. Il faut également enregistrer ce serveur DNS sur le serveur qui gère .milxc.

Ceci se passe dans groups/milxc/ns/provision.sh, il suffit de reproduire l'exemple de isp-a.milxc. Ensuite, `./mi-lxc.py destroy milxc-ns && ./mi-lxc.py create`


IV.6-Faire un nouveau template
-----------------------------

MI-LXC propose deux mécanismes de templates :
* des templates de groupe, définis dans `templates/groups/`. Nous avons utilisé ici as-bgp par exemple, qui crée un routeur de bordure d'AS avec Alpine Linux. Le template as-bgp-debian produit la même fonctionnalité mais avec un routeur Debian.
* des templates d'hôtes, définis dans `templates/hosts/<family>/`. Quand on dérive d'un master Debian (ce qui est le défaut, les masters sont définis dans global.json), les templates sont recherchés dans `templates/hosts/debian/`

Nous allons ajouter un template d'hôte permettant de faire un greeting dans le .bashrc, identique pour de nombreuses machines. Créez un sous-dossier pour ce template, un script provision.sh similaire à celui d'un hôte, puis appelez ce template dans l'hôte précédemment créé.


V-Développeur - Le développement du moteur de MI-LXC
====================================================

Enfin, nous allons explorer un peu le code Python du framework, en regardant le chemin pour ajouter un backend d'exécution. Aujourd'hui, MI-LXC support l'exécution de conteneurs LXC et l'émulation de routeurs Cisco (dynamips), ces deux éléments étant définis dans le dossier backends/.

Nous allons voir comment on pourrait ajouter un backend Vagrant/VirtualBox pour virtualiser des hôtes Windows par exemple. Tout d'abord, il faut créer un nouveau master dans `global.json`. Par exemple :
```
{
"backend":"lxc",
"template":"download",
"parameters":{"dist": "debian", "release": "buster", "arch": "amd64", "no-validate": "true"},
"family":"debian",
"name":"buster"
},
```
spécifie que :
* Le nom du backend à utiliser est "lxc" (à changer, donc)
* Le champ family indique que les templates seront à chercher dans le dossier `templates/hosts/<family>`
* Le champ name nomme le template
* Le reste (template, parameters ici) est libre et sera lu par le backend spécifié

Créez donc un nouveau master avec un autre backend inexistant. Ensuite, `./mi-lxc.py print` va vous indiquer la ligne de `mi-lxc.py` où il faut rajouter le cas de ce nouveau backend (dans getMasters2()). En vous inspirant des 2 cas existants, vous serez amené à ajouter un cas et à créer un objet d'un nouveau type, à définir dans le dossier backends. Vous pouvez repartir de backends/HostBackend pour avoir un squelette vide et ainsi une idée des fonctions qui seront à remplir.

L'idée dans ce tutoriel n'est, évidemment, pas d'écrire ce nouveau backend, mais il devra :
* proposer 2 classes : une pour les masters, une pour les hôtes
* les exemples LXC et Dynamips montrent comment mutualiser une partie de ces deux classes dans une classe commune. La fichier LxcBackend.py peut d'ailleurs être repris pour le début de nombreuses fonctions.
* il faudra rajouter le paramètre `master:LeNouveauMaster` aux hôtes qui devraient utiliser ce nouveau master
* l'ajout sur les hôtes fera apparaître une seconde condition (dans getHosts()) dans laquelle il faut rajouter le cas de ce backend
* YOLO !
