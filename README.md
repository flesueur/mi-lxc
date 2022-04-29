# MI-LXC : Mini-Internet using LXC&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <img src="https://github.com/flesueur/mi-lxc/blob/master/doc/logo.png" width="100" style="float: right;">

[![fr](https://img.shields.io/badge/lang-fr-informational)](https://github.com/flesueur/mi-lxc/blob/master/doc/README.fr.md)

MI-LXC uses LXC to simulate an internet-like environment. I use this environment for (infosec) practical work (intrusion, firewall, IDS, etc.). The small memory footprint of LXC combined with differential images allows to run it on modest hardware.

It is based on the infrastructure-as-code principle: these scripts programmatically generate the target environment.

Example practical work using this environment (in french) :

* [Intrusion scenario](https://git.kaz.bzh/francois.lesueur/LPCyber/src/branch/master/tp1-intrusion.md) (adapted to MI-LXC v1.4.0)
* [Firewall](https://github.com/flesueur/srs/blob/master/tp2-firewall.md) (adapted to MI-LXC v1.3.0)
* [IDS](https://git.kaz.bzh/francois.lesueur/LPCyber/src/branch/master/tp2-idps.md) (adapted to MI-LXC v1.4.0)
* [CA](https://github.com/flesueur/csc/blob/master/tp1-https.md) (adapted to MI-LXC v1.3.0)
* [MI-LXC walkthrough](https://git.kaz.bzh/francois.lesueur/M3102/src/branch/master/td1.1-milxc.md) (adapted to MI-LXC v1.4.0)
* [DNS](https://git.kaz.bzh/francois.lesueur/M3102/src/branch/master/td3.1-dns.md) (adapted to MI-LXC v1.4.0)
* [Mail](https://git.kaz.bzh/francois.lesueur/M3102/src/branch/master/td4.1-mail.md) (adapted to MI-LXC v1.4.0)
* [LDAP](https://git.kaz.bzh/francois.lesueur/LPCyber/src/branch/master/tp7-ldap.md) (adapted to MI-LXC v1.4.1)
* [MitM / ARP spoofing](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP1-MitM.md) (by Sébastien Mériot)
* [Crypto](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP3-crypto.md) (by Sébastien Mériot)
* [HTTP Proxy](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP5-IDS.md) (by Sébastien Mériot)
* [DFIR 1](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/984b44c3c644dffe1c898fd6f5b3f5719e0c6e58/TP6-DFIR.md) / [DFIR 2](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP6-DFIR.md) (by Sébastien Mériot)

There is also a [walkthrough tutorial](doc/TUTORIAL.md) and a [video](https://www.youtube.com/watch?v=waCsmE7BeZs).

![Topology](https://github.com/flesueur/mi-lxc/blob/master/doc/topologie.png)


# Features and composition

Features :

* Containers run up-to-date Debian Bullseye or Alpine Linux
* The infrastructure-as-code principle allows for easy management, deployment and evolution along time
* The infrastructure is built by final users on their own PC
* Every container also have access to the real internet (for software installation)
* Containers provide shell access as well as X11 interface

The example network is composed of :

* some transit/ISP routed through BGP to simulate a core network
* an alternative DNS root, allowing to resolve real TLDs + a custom ".milxc" TLD (the .milxc registry is maintained inside MI-LXC)
* some residential ISP clients (hacker and a random PC), using mail adresses \@isp-a.milxc
* a target organization, owning its own AS number, running classical services (HTTP, mail, DNS, filer, NIS, clients, etc.) for target.milxc domain
* a certification authority (MICA) ready for ACME (Let's Encrypt-style)

A few things you can do and observe :

* You can http `dmz.target.milxc` from `isp-a-hacker`. Packets will go through the core BGP network, where you should be able to observe them or alter the routes
* You can query the DNS entry `smtp.target.milxc` from `isp-a-hacker`. `isp-a-hacker` will ask the resolver at `isp-a-infra`, which will recursively resolve from the DNS root `ns-root-o`, then from `reg-milxc` and finally from `target-dmz`
* You can send an email from `hacker@isp-a.milxc` (or another forged address...), using claws-mail on `isp-a-hacker`, to `commercial@target.milxc`, which can be read using claws-mail on `target-commercial` (with X11 sessions in both containers)

The "IANA-type" numbering (AS numbers, IP space, TLDs) is described in [doc/MI-IANA.txt](https://github.com/flesueur/mi-lxc/blob/master/doc/MI-IANA.txt). There is currently no cryptography deployed anywhere (no HTTPS, no IMAPS, no DNSSEC, etc.). This will probably be added at some point but in the meantime, deploying this is part of the expected work from students.

More precise details on what is installed and configured on hosts is in [doc/DETAILS.md](doc/DETAILS.md).

# How to use

## Installation

You can either:
* Download the [latest ready-to-run VirtualBox VM](https://github.com/flesueur/mi-lxc/releases/latest). Login with root/root, then MI-LXC is already installed and provisionned in `/root/mi-lxc/` (i.e., you can directly `./mi-lxc.py start`, no need to `./mi-lxc.py create`)
* Create a [VirtualBox VM using Vagrant](doc/INSTALL.md#installation-on-windowsmacoslinux-using-vagrant). Login with root/root, then MI-LXC is already installed and provisionned in `/root/mi-lxc/` (i.e., you can directly `./mi-lxc.py start`, no need to `./mi-lxc.py create`)
* Install [directly on your Linux host system](doc/INSTALL.md#installation-on-linux)


Usage
-----

The `mi-lxc.py` script generates and uses containers (as *root*, since it manipulates bridges and lxc commands, more on this [here](#what-is-done-with-root-permissions-)). It is used as `./mi-lxc.py <command>`, with the following commands:

| Command                          | Description |
| -------------------------------- | ----------- |
| `create [name]`                  | Creates the [name] container, defaults to create all containers
| `renet`                          | Renets all the containers
| `destroy [name]`                 | Destroys the [name] container, defaults to destroy all containers
| `destroymaster`                  | Destroys all the master containers
| `updatemaster`                   | Updates all the master containers
| `start`                          | Starts the created infrastructure
| `stop`                           | Stops the created infrastructure
| `attach [user@]<name> [command]` | Attaches a term on \<name> as [user](defaults to root) and executes [command](defaults to interactive shell)
| `display [user@]<name>`          | Displays a graphical desktop on \<name> as [user](defaults to debian)
| `print`                          | Graphically displays the defined architecture
|                                  | (\<arguments> are mandatory and [arguments] are optional)|


There is also a [walkthrough tutorial](doc/TUTORIAL.md).


## What is done with root permissions ?

* Manipulation of LXC containers (no unprivileged LXC usage yet)
* Management of virtual ethernet bridges with `brctl`, `ifconfig` and `iptables` (in mi-lxc.py:createBridges() and mi-lxc.py:deleteBridges(), around [line 324](https://github.com/flesueur/mi-lxc/blob/master/mi-lxc.py#L324))
* Increase of fs.inotify.max_queued_events, fs.inotify.max_user_instances and fs.inotify.max_user_watches through `sysctl` (in mi-lxc.py:increaseInotify(), around [line 278](https://github.com/flesueur/mi-lxc/blob/master/mi-lxc.py#L278))

This is not ideal but is currently needed. An [issue](https://github.com/flesueur/mi-lxc/issues/9) is opened on the topic but it is not currently planned.


# How to extend

The address space is explained in [MI-IANA.txt](doc/MI-IANA.txt) and the global topology is defined in [global.json](global.json). It describes:

* masters, in the `masters/` subfolder (currently a Debian Buster and an Alpine Linux)
* groups of hosts, typically AS interconnected with BGP

Groups of hosts are described through:

* group templates in `templates/groups/<groupname>/local.json`, which typically provides a `as-bgp` group template to setup an AS
* enriched with local specifications in `groups/<groupname>/local.json`

Finally, hosts are described and provisonned through:

* host templates in `templates/hosts/<family>/<template>/provision.sh`, which typically provide templates for BGP routers, mail servers, mail clients, ...
* specific scripts for a given host in `groups/<groupname>/<hostname>/provision.sh`

To extend it, you can either extend an existing AS (typically, Target) or create a new AS. In this second case, you can duplicate Target and then connect it to some transit operator under a new AS number (all BGP-related configuration is specified in `global.json`).

This process is described in the [walkthrough tutorial](doc/TUTORIAL.md).


# License
This software is licensed under AGPLv3 : you can freely reuse it as long as you write you use it and you redistribute your modifications. Special licenses with (even) more liberties for public teaching activities can be discussed.
