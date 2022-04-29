# MI-LXC : Mini-Internet utilisant LXC&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <img src="https://github.com/flesueur/mi-lxc/blob/master/doc/logo.png" width="100" style="float: right;">

[![en](https://img.shields.io/badge/lang-en-informational)](https://github.com/flesueur/mi-lxc#readme)

MI-LXC utilise LXC pour simuler un environnement de type Internet. J'utilise cet environnement pour des travaux pratiques (infosec) (intrusion, firewall, IDS, etc.). La faible empreinte mémoire de LXC combinée aux images différentielles permet de l'exécuter sur du matériel modeste.

Il est basé sur le principe de l'infrastructure en tant que code : ces scripts génèrent de manière programmatique l'environnement cible.

Exemple de travaux pratiques utilisant cet environnement :

* [Intrusion scenario](https://git.kaz.bzh/francois.lesueur/LPCyber/src/branch/master/tp1-intrusion.md) (adapté à MI-LXC v1.4.0)
* [Firewall](https://github.com/flesueur/srs/blob/master/tp2-firewall.md) (adapté à MI-LXC v1.3.0)
* [IDS](https://git.kaz.bzh/francois.lesueur/LPCyber/src/branch/master/tp2-idps.md) (adapté à MI-LXC v1.4.0)
* [CA](https://github.com/flesueur/csc/blob/master/tp1-https.md) (adapté à MI-LXC v1.3.0)
* [Découverte MI-LXC](https://git.kaz.bzh/francois.lesueur/M3102/src/branch/master/td1.1-milxc.md) (adapté à MI-LXC v1.4.0)
* [DNS](https://git.kaz.bzh/francois.lesueur/M3102/src/branch/master/td3.1-dns.md) (adapté à MI-LXC v1.4.0)
* [Mail](https://git.kaz.bzh/francois.lesueur/M3102/src/branch/master/td4.1-mail.md) (adapté à MI-LXC v1.4.0)
* [LDAP](https://git.kaz.bzh/francois.lesueur/LPCyber/src/branch/master/tp7-ldap.md) (adapté à MI-LXC v1.4.1)
* [MitM / ARP spoofing](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP1-MitM.md) (par Sébastien Mériot)
* [Crypto](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP3-crypto.md) (par Sébastien Mériot)
* [HTTP Proxy](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP5-IDS.md) (par Sébastien Mériot)
* [DFIR 1](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/984b44c3c644dffe1c898fd6f5b3f5719e0c6e58/TP6-DFIR.md) / [DFIR 2](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP6-DFIR.md) (par Sébastien Mériot)

Il existe également un [tutoriel pas à pas](TUTORIAL.fr.md) et une [vidéo de présentation](https://www.sstic.org/2020/presentation/mi-lxc_une_plateforme_pedagogique_pour_la_securite_reseau/).

![Topologie](https://github.com/flesueur/mi-lxc/blob/master/doc/topologie.png)


# Fonctionnalités et composition

Fonctionnalités :

* Les conteneurs fonctionnent avec les dernières versions de Debian Bullseye ou Alpine Linux.
* Le principe de l'infrastructure en tant que code permet une gestion, un déploiement et une évolution faciles dans le temps.
* L'infrastructure est construite par les utilisateurs finaux sur leur propre PC.
* Chaque conteneur a également accès à l'Internet réel (pour l'installation de logiciels).
* Les conteneurs fournissent un accès shell ainsi qu'une interface X11.

Le réseau d'exemple est composé de :

* quelques transit/ISP routés par BGP pour simuler un réseau central.
* une racine DNS alternative, permettant de résoudre les TLD réels + un TLD personnalisé ".milxc" (le registre .milxc est maintenu au sein de MI-LXC)
* quelques clients ISP résidentiels (le pirate et un PC aléatoire), utilisant les adresses de courrier \@isp-a.milxc
* une organisation cible, possédant son propre numéro d'AS, exécutant des services classiques (HTTP, courrier, DNS, filer, NIS, clients, etc.) pour le domaine target.milxc.
* Une autorité de certification (MICA) prête pour ACME (style Let's Encrypt).

Quelques éléments que vous pouvez faire et observer :

* Vous pouvez http `dmz.target.milxc` depuis `isp-a-hacker`. Les paquets passeront par le cœur du réseau BGP, où vous devriez être en mesure de les observer ou de modifier les routes.
* Vous pouvez interroger l'entrée DNS `smtp.target.milxc` depuis `isp-a-hacker`. `isp-a-hacker` demandera au résolveur de `isp-a-infra`, qui résoudra récursivement à partir de la racine DNS `ns-root-o`, puis de `reg-milxc` et enfin de `target-dmz`.
* Vous pouvez envoyer un email de `hacker@isp-a.milxc` (ou une autre fausse adresse...), en utilisant claws-mail sur `isp-a-hacker`, à `commercial@target.milxc`, qui peut être lu en utilisant claws-mail sur `target-commercial` (avec des sessions X11 dans les deux conteneurs).

La numérotation de type "IANA" (numéros d'AS, espace IP, TLD) est décrite dans [doc/MI-IANA.fr.txt](https://github.com/flesueur/mi-lxc/blob/master/doc/MI-IANA.fr.txt). Actuellement, aucune cryptographie n'est déployée nulle part (pas de HTTPS, pas d'IMAPS, pas de DNSSEC, etc.). Cela sera probablement ajouté à un moment donné, mais en attendant, le déploiement fait partie du travail attendu des étudiants.

Des détails plus précis sur ce qui est installé et configuré sur les hôtes se trouvent dans [doc/DETAILS.fr.md](doc/DETAILS.fr.md).

# Utilisation

## Installation

Vous pouvez soit :
* Télécharger la [dernière version de VirtualBox VM prête à fonctionner] (https://github.com/flesueur/mi-lxc/releases/latest). Connectez-vous avec root/root, MI-LXC est alors déjà installé et provisionné dans `/root/mi-lxc/` (c'est-à-dire que vous pouvez directement `./mi-lxc.py start`, pas besoin de `./mi-lxc.py create`).
* Créez une [VirtualBox VM en utilisant Vagrant](doc/INSTALL.fr.md#installation-sur-windowsmacoslinux-utilisant-vagrant). Connectez-vous avec root/root, MI-LXC est alors déjà installé et provisionné dans `/root/mi-lxc/` (i.e., vous pouvez directement `./mi-lxc.py start`, pas besoin de `./mi-lxc.py create`).
* Installer [directement sur votre système hôte Linux](doc/INSTALL.fr.md#installation-sur-linux)


Utilisation
-------------

Le script `mi-lxc.py` génère et utilise les conteneurs (en tant que *root*, puisqu'il manipule les ponts et les commandes lxc, plus d'informations à ce sujet [ici](#qu-est-ce-qui-est-fait-avec-les-permissions-de-root-)). Il s'utilise sous la forme `./mi-lxc.py <commande>`, avec les commandes suivantes :

| Commande                         | Description |
| -------------------------------- | ----------- |
| `create [name]`                  | Crée le conteneur [name], par défaut crée tous les conteneurs
| `renet`                          | Reconfigure le réseau de tous les conteneurs
| `destroy [name]`                 | Détruit le conteneur [name], par défaut tous les conteneurs
| `destroymaster`                  | Détruit tous les conteneurs masters
| `updatemaster`                   | Met à jour tous les conteneurs masters
| `start`                          | Démarre l'infrastructure générée
| `stop`                           | Arrête l'infrastructure générée
| `attach [user@]<name> [command]` | Attache un terminal sur \<name> en tant que [user](par défaut root) et exécute [command](par défaut un shell interactif)
| `display [user@]<name>`          | Affiche un bureau graphique sur \<name> en tant que [user](par défaut debian)
| `print`                          | Affiche la topologie configurée
|                                  | (\<arguments> sont obligatoires et [arguments] sont optionnels)|

Il y a également un [tutoriel pas à pas](doc/TUTORIAL.fr.md).


## Qu'est ce qui est fait avec les permissions de root ?

* Manipulation des conteneurs LXC (pas encore d'utilisation non privilégiée de LXC)
* Gestion des ponts ethernet virtuels avec `brctl`, `ifconfig` et `iptables` (dans mi-lxc.py:createBridges() et mi-lxc.py:deleteBridges(), autour de [ligne 324](https://github.com/flesueur/mi-lxc/blob/master/mi-lxc.py#L324))
* Augmentation de fs.inotify.max_queued_events, fs.inotify.max_user_instances et fs.inotify.max_user_watches par `sysctl` (in mi-lxc.py:increaseInotify(), environ [ligne 278](https://github.com/flesueur/mi-lxc/blob/master/mi-lxc.py#L278))

Ce n'est pas idéal mais c'est actuellement nécessaire. Une [issue](https://github.com/flesueur/mi-lxc/issues/9) est ouverte sur le sujet mais ce n'est pas prévu actuellement.


# Comment l'étendre

L'espace d'adressage est expliqué dans [MI-IANA.fr.txt](doc/MI-IANA.fr.txt) et la topologie globale est définie dans [global.json](global.json). Elle décrit :

* les maîtres, dans le sous-dossier `masters/` (actuellement un Debian Buster et un Alpine Linux)
* des groupes d'hôtes, typiquement des AS interconnectés avec BGP.

Les groupes d'hôtes sont décrits à travers :

* des modèles de groupes dans `templates/groups/<groupname>/local.json`, qui fournit typiquement un modèle de groupe `as-bgp` pour configurer un AS.
* enrichi de spécifications locales dans `groups/<groupname>/local.json`.

Enfin, les hôtes sont décrits et fournis à travers :

* des modèles d'hôtes dans `templates/hosts/<family>/<template>/provision.sh`, qui fournissent généralement des modèles pour les routeurs BGP, les serveurs de messagerie, les clients de messagerie, ...
* des scripts spécifiques pour un hôte donné dans `groups/<groupname>/<hostname>/provision.sh`.

Pour l'étendre, vous pouvez soit étendre un AS existant (typiquement, Target), soit créer un nouvel AS. Dans ce deuxième cas, vous pouvez dupliquer Target et le connecter à un opérateur de transit sous un nouveau numéro d'AS (toute la configuration relative à BGP est spécifiée dans `global.json`).

Ce processus est décrit dans le [tutoriel pas à pas](doc/TUTORIAL.fr.md).


# Licence
Ce logiciel est sous licence AGPLv3 : vous pouvez le réutiliser librement à condition d'écrire que vous l'utilisez et de redistribuer vos modifications. Des licences spéciales avec (encore) plus de libertés pour les activités d'enseignement public peuvent être discutées.
