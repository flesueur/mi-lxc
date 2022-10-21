# MI-LXC : Mini-Internet using LXC&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <img src="https://github.com/flesueur/mi-lxc/blob/master/doc/logo.png" width="100" style="float: right;">

[![fr](https://img.shields.io/badge/lang-fr-informational)](https://github.com/flesueur/mi-lxc/blob/master/doc/README.fr.md)

MI-LXC uses LXC to simulate an internet-like environment. I use this environment for (infosec) practical work (intrusion, firewall, IDS, etc.). The small memory footprint of LXC combined with differential images allows to run it on modest hardware.

It is based on the infrastructure-as-code principle: these scripts programmatically generate the target environment.

Since version 2.0, MI-LXC uses [SNSTER](https://framagit.org/flesueur/snster) under the hood. Compared to previous monolithic versions, the framework (python code, templates, masters) has been splitted to SNSTER and configuration format has changed (YAML instead of JSON and different organization). This MI-LXC repository now only contains a topology configuration (`topology/` subfolder) simulating a mini-internet on top of SNSTER. The `vagrant` subdirectory creates a ready-to-use VM with both SNSTER and MI-LXC. The releases link to such VMs.

Example practical work using this environment (in french) (note that commands and internals have changed between v1.4.x and v2.x) :

* [Intrusion scenario](https://git.kaz.bzh/francois.lesueur/LPCyber/src/branch/master/tp1-intrusion.md) (adapted to MI-LXC v1.4.0)
* [Firewall / Network segmentation](https://git.kaz.bzh/francois.lesueur/M3102/src/branch/master/td7-archi.md) (adapted to MI-LXC v1.4.2)
* [IDS](https://git.kaz.bzh/francois.lesueur/LPCyber/src/branch/master/tp2-idps.md) (adapted to MI-LXC v1.4.0)
* [CA / HTTPS](https://git.kaz.bzh/francois.lesueur/LPCyber/src/branch/master/tp4-https.md) (adapted to MI-LXC v1.4.0)
* [DNS](https://git.kaz.bzh/francois.lesueur/M3102/src/branch/master/td5-dns.md) (adapted to MI-LXC v1.4.2)
* [Mail](https://git.kaz.bzh/francois.lesueur/M3102/src/branch/master/td6-mail.md) (adapted to MI-LXC v1.4.2)
* [LDAP](https://git.kaz.bzh/francois.lesueur/LPCyber/src/branch/master/tp7-ldap.md) (adapted to MI-LXC v1.4.1)
* [HTTP / Apache](https://git.kaz.bzh/francois.lesueur/M3102/src/branch/master/td4-apache.md) (adapted to MI-LXC v1.4.2)
* [MI-LXC walkthrough](https://git.kaz.bzh/francois.lesueur/M3102/src/branch/master/td1-milxc.md) (adapted to MI-LXC v1.4.2)
* [MitM / ARP spoofing](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP1-MitM.md) (by Sébastien Mériot)
* [Crypto](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP3-crypto.md) (by Sébastien Mériot)
* [HTTP Proxy](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP5-IDS.md) (by Sébastien Mériot)
* [DFIR 1](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/984b44c3c644dffe1c898fd6f5b3f5719e0c6e58/TP6-DFIR.md) / [DFIR 2](https://github.com/PandiPanda69/edu-isen-tp-ap4/blob/main/TP6-DFIR.md) (by Sébastien Mériot)

There is also a [walkthrough tutorial](doc/TUTORIAL.md) and a [video](https://www.youtube.com/watch?v=waCsmE7BeZs) (the video is related to v1).

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
* You can send an email from `hacker@isp-a.milxc` (or another forged address...), using claws-mail on `isp-a-hacker`, to `sales@target.milxc`, which can be read using claws-mail on `target-sales` (with X11 sessions in both containers)

The "IANA-type" numbering (AS numbers, IP space, TLDs) is described in [doc/MI-IANA.txt](https://github.com/flesueur/mi-lxc/blob/master/doc/MI-IANA.txt). There is currently no cryptography deployed anywhere (no HTTPS, no IMAPS, no DNSSEC, etc.). This will probably be added at some point but in the meantime, deploying this is part of the expected work from students.

More precise details on what is installed and configured on hosts is in [doc/DETAILS.md](doc/DETAILS.md).

# How to use

## Installation

You can either:
* Download the [latest ready-to-run VirtualBox VM](https://github.com/flesueur/mi-lxc/releases/latest). Login with root/root, then MI-LXC is already installed and provisionned in `/root/mi-lxc/` (i.e., you can directly `snster start`, no need to `snster create`)
* Create a [VirtualBox VM using Vagrant](doc/INSTALL.md#installation-on-windowsmacoslinux-using-vagrant). Login with root/root, then MI-LXC is already installed and provisionned in `/root/mi-lxc/` (i.e., you can directly `snster start`, no need to `snster create`)
* Install [directly on your Linux host system](doc/INSTALL.md#installation-on-linux)


Usage
-----

The `snster` script generates and uses containers (as *root*, since it manipulates bridges and lxc commands, more on this [here](#what-is-done-with-root-permissions-)). It is used as `snster <command>`, with the following commands:

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


# How to extend

The address space is explained in [MI-IANA.txt](doc/MI-IANA.txt) and the global topology is defined in [topology/](topology/). It describes:

* the global configuration in [topology/main.yml](topology/main.yml)
* groups of hosts, typically AS interconnected with BGP, in the subfolders of [topology/](topology/)

Each group of hosts is described through a group.yml file in its subfolder.

Finally, hosts are described and provisonned through:
* host templates in SNSTER, which typically provide templates for BGP routers, mail servers, mail clients, ...
* specific scripts for a given host in `topology/<groupname>/<hostname>/provision.sh`

To extend it, you can either extend an existing AS (typically, Target) or create a new AS. In this second case, you can duplicate Target and then connect it to some transit operator under a new AS number.

This process is described in the [walkthrough tutorial](doc/TUTORIAL.md).


# License
This software is licensed under AGPLv3 : you can freely reuse it as long as you write you use it and you redistribute your modifications. Special licenses with (even) more liberties for public teaching activities can be discussed.
