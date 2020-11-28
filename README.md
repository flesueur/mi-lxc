# <img src="https://github.com/flesueur/mi-lxc/blob/master/logo.png" width="100"> Mini-Internet using LXC

MI-LXC uses LXC to simulate an internet-like environment. I use this environment for (infosec) practical work (intrusion, firewall, IDS, etc.). The small memory footprint of LXC combined with differential images allows to run it on modest hardware.

It is based on the infrastructure-as-code principle: these scripts programmatically generate the target environment.

Example practical work using this environment (in french) :

* [Intrusion scenario](https://github.com/flesueur/srs/blob/master/tp1-intrusion.md) (adapted to MI-LXC v1.3.0)
* [Firewall](https://github.com/flesueur/srs/blob/master/tp2-firewall.md) (adapted to MI-LXC v1.3.0)
* [IDS](https://github.com/flesueur/srs/blob/master/tp3-ids.md) (adapted to MI-LXC v1.3.0)
* [CA](https://github.com/flesueur/csc/blob/master/tp1-openssl.md) (adapted to MI-LXC v1.2.0)

![Topology](https://github.com/flesueur/mi-lxc/blob/master/topologie.png)


# Features and composition

Features :

* Containers run up-to-date Debian Buster or Alpine Linux
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
* MISP instances on misp.target.milxc (on target-dmz) and misp.gozilla.milxc (on gozilla-infra)

A few things you can do and observe :

* You can http `dmz.target.milxc` from `isp-a-hacker`. Packets will go through the core BGP network, where you should be able to observe them or alter the routes
* You can query the DNS entry `smtp.target.milxc` from `isp-a-hacker`. `isp-a-hacker` will ask the resolver at `isp-a-infra`, which will recursively resolve from the DNS root `ns-root-o`, then from `reg-milxc` and finally from `target-dmz`
* You can send an email from `hacker@isp-a.milxc` (or another forged address...), using claws-mail on `isp-a-hacker`, to `commercial@target.milxc`, which can be read using claws-mail on `target-commercial` (with X11 sessions in both containers)

The "IANA-type" numbering (AS numbers, IP space, TLDs) is described in [MI-IANA.txt](https://github.com/flesueur/mi-lxc/blob/master/MI-IANA.txt). There is currently no cryptography deployed anywhere (no HTTPS, no IMAPS, no DNSSEC, etc.). This will probably be added at some point but in the meantime, deploying this is part of the expected work from students.

More precise details on what is installed and configured on hosts is in [DETAILS.md](DETAILS.md).

# How to use

## Installation on Linux

On Debian (Strech/Buster), you need lxc, python3-lxc, dnsmasq-base, bridge-utils, python3-pil and python3-pygraphviz (`apt-get install lxc python3-lxc dnsmasq-base bridge-utils python3-pil python3-pygraphviz`) and then to enable networking in the LXC configuration (`USE_LXC_BRIDGE="true"` in `/etc/default/lxc-net`). Finally, you need to restart LXC networking (`service lxc-net restart`).

On Ubuntu Bionic (2018.04 LTS), you first need to enable the multiverse repository. Then you need to install lxc-utils, python3-lxc dnsmasq-base, python3-pil and python3-pygraphviz (`apt-get install lxc-utils python3-lxc dnsmasq-base python3-pil python3-pygraphviz`). You may need to restart lxc-net or apparmor. If you are using Ubuntu as a live CD, you need some mounted storage (4GB should be ok) and then to configure LXC to use this space : create the `/etc/lxc/lxc.conf` with the content `lxc.lxcpath=/mnt` (location where you mounted your storage)

On Kali 2018.2, you need lxc (`apt-get install lxc`) and then to enable networking in the LXC configuration (`USE_LXC_BRIDGE="true"` in `/etc/default/lxc-net`). Finally, you need to restart LXC and AppArmor (`service lxc restart && service apparmor restart`). If you are using Kali as a live CD, you need some mounted storage (4GB should be ok) and then to configure LXC to use this space : create the `/etc/lxc/lxc.conf` with the content `lxc.lxcpath=/mnt` (location where you mounted your storage)

On Arch Linux, you need to downgrade LXC to LXC 2.0.7 (it should now work with LXC 3, reports welcome), then to install python3-lxc from the official lxc github. You also need dnsmasq and python-graphviz. Rest of the configuration is quite similar (network configuration, service restart, etc.)

> Optionally, you can:
> * install `apt-cacher-ng` on your host (port 3142) to speed up the creation of the containers. This proxy is detected in [masters/buster/detect_proxy.sh](https://github.com/flesueur/mi-lxc/blob/master/masters/buster/detect_proxy.sh).
> * install the bash autocompletion script `milxc-completion.bash`, either by sourcing it in your current shell (`source milxc-completion.bash`) or by copying it in `/etc/bash_completion.d/`

## Installation on Windows/MacOS/Linux (using Vagrant)

The `vagrant` subdirectory contains a `Vagrantfile` suited to generate a VirtualBox VM running MI-LXC inside. You need to install [Vagrant](https://www.vagrantup.com/downloads.html) and then, in the `vagrant` subdirectory, run `vagrant up`. You can then login as root/root. MI-LXC is installed in `/root/mi-lxc` and already provisionned (no need to `create`, you can directly `start`).


Usage
-----

The `mi-lxc.py` script generates and uses containers (as *root*, since it manipulates bridges and lxc commands, more on this [here](#what-is-done-with-root-permissions-))

<!-- * `./mi-lxc.py addbridges     # Create required network bridges on the host` -->
* `./mi-lxc.py print         # Displays the configured topology`
* `./mi-lxc.py create         # Creates master containers and then clones it to create all the containers`
* `./mi-lxc.py start          # Start the generated infrastructure  (stop to stop it)`
* `./mi-lxc.py attach [user@]<name> [command]  # Executes [command] in the container <name> as user [user]. [command] and [user] are optional; if not specified, user is root and command is an interactive shell.`
* `./mi-lxc.py display [user@]<name> # X11 access to the container <name>. Default user is debian`
* `./mi-lxc.py renet         # Updates containers network interfaces and setups to reflect topology changes (global.json/local.json)`
* `./mi-lxc.py                # Usage and list of container names`
* `./mi-lxc.py destroy && ./mi-lxc.py destroymaster   # Destroys everything (master containers and all linked containers)`


## What is done with root permissions ?

* Manipulation of LXC containers (no unprivileged LXC usage yet)
* Management of virtual ethernet bridges with `brctl`, `ifconfig` and `iptables` (in mi-lxc.py:createBridges() and mi-lxc.py:deleteBridges(), around [line 324](https://github.com/flesueur/mi-lxc/blob/master/mi-lxc.py#L324))
* Increase of fs.inotify.max_queued_events, fs.inotify.max_user_instances and fs.inotify.max_user_watches through `sysctl` (in mi-lxc.py:increaseInotify(), around [line 278](https://github.com/flesueur/mi-lxc/blob/master/mi-lxc.py#L278))

This is not ideal but is currently needed. An [issue](https://github.com/flesueur/mi-lxc/issues/9) is opened on the topic but it is not currently planned.


# How to extend

The address space is explained in `MI-IANA.txt` and the global topology is defined in `global.json`. It describes:

* masters, in the `masters/` subfolder (currently a Debian Buster and an Alpine Linux)
* groups of hosts, typically AS interconnected with BGP

Groups of hosts are described through:

* group templates in `templates/groups/<groupname>/local.json`, which typically provides a `as-bgp` group template to setup an AS
* enriched with local specifications in `groups/<groupname>/local.json`

Finally, hosts are described and provisonned through:

* host templates in `templates/hosts/<family>/<template>/provision.sh`, which typically provide templates for BGP routers, mail servers, mail clients, ...
* specific scripts for a given host in `groups/<groupname>/<hostname>/provision.sh`

To extend it, you can either extend an existing AS (typically, Target) or create a new AS. In this second case, you can duplicate Target and then connect it to some transit operator under a new AS number (all BGP-related configuration is specified in `global.json`)


# License
This software is licensed under AGPLv3 : you can freely reuse it as long as you write you use it and you redistribute your modifications. Special licenses with (even) more liberties for public teaching activities can be discussed.
