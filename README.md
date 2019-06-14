# MI-LXC : Mini-Internet using LXC

MI-LXC uses LXC to simulate a small-scale internet-like environment. I use this environment for (infosec) practical work (intrusion, firewall, IDS, etc.). The small memory footprint of LXC combined with differential images allows to run it on modest hardware.

It is based on the infrastructure-as-code principle: these scripts programmatically generate the target environment.

Example practical work using this environment (in french) :

* [Intrusion scenario](https://github.com/flesueur/srs/blob/master/tp1-intrusion.md)
* [Firewall](https://github.com/flesueur/srs/blob/master/tp2-firewall.md)
* [IDS](https://github.com/flesueur/srs/blob/master/tp3-ids.md)

![Topology](https://github.com/flesueur/mi-lxc/blob/master/topologie.png)


# Features and composition

Features :

* Containers run up-to-date Debian Stretch
* The infrastructure-as-code principle allows for easy management, deployment and evolution along time
* The infrastructure is built by final users on their own PC
* Every container also have access to the real internet (software installation)
* Containers provide shell access as well as X11 interface

The example network is composed of :

* some transit/ISP routed through BGP to simulate a core network
* an alternative DNS root, allowing to resolve real TLD + a custom ".milxc" TLD (the .milxc registry is maintained inside MI-LXC)
* some residential ISP clients (hacker and a random PC), using mail adresses \@isp-a.milxc
* a target organization, owning its own AS number, running classical services (HTTP, mail, DNS, filer, NIS, clients, etc.) for target.milxc domain

The "IANA-type" numbering (AS numbers, IP space, TLDs) is described in ![MI-IANA.txt](https://github.com/flesueur/mi-lxc/blob/master/MI-IANA.txt)


# How to use

The `files` subdirectory contains files and scripts to provision the containers. The `mi-lxc.py` script generates and uses containers (as *root*, since it manipulates bridges and lxc commands). The topology is defined in `setup.json` (not yet documented)

Optionally, you can install `apt-cacher-ng` on your host (port 3142) to speed up the creation of the containers. This proxy is detected in ![files/master/detect_proxy.sh](https://github.com/flesueur/mi-lxc/blob/master/files/master/detect_proxy.sh).

## Installation on Linux

On Debian Strech, you need lxc (`apt-get install lxc`) and then to enable networking in the LXC configuration (`USE_LXC_BRIDGE="true"` in `/etc/default/lxc-net`). Finally, you need to restart LXC networking (`service lxc-net restart`).

On Ubuntu Bionic (2018.04 LTS), you first need to enable the multiverse repository. Then you need to install lxc-utils and python3-lxc (`apt-get install lxc-utils python3-lxc`). You may need to restart lxc-net or apparmor. If you are using Ubuntu as a live CD, you need some mounted storage (4GB should be ok) and then to configure LXC to use this space : create the `/etc/lxc/lxc.conf` with the content `lxc.lxcpath=/mnt` (location where you mounted your storage)

On Kali 2018.2, you need lxc (`apt-get install lxc`) and then to enable networking in the LXC configuration (`USE_LXC_BRIDGE="true"` in `/etc/default/lxc-net`). Finally, you need to restart LXC and AppArmor (`service lxc restart && service apparmor restart`). If you are using Kali as a live CD, you need some mounted storage (4GB should be ok) and then to configure LXC to use this space : create the `/etc/lxc/lxc.conf` with the content `lxc.lxcpath=/mnt` (location where you mounted your storage)

On Arch Linux, you need to downgrade LXC to LXC 2.0.7 (it should now work with LXC 3, reports welcome), then to install python3-lxc from the official lxc github. You also need dnsmasq. Rest of the configuration is quite similar (network configuration, service restart, etc.)


## Installation on Windows/MacOS/Linux (using Vagrant)

The `vagrant` subdirectory contains a `Vagrantfile` suited to generate a VirtualBox VM running MI-LXC inside. You need to install [Vagrant](https://www.vagrantup.com/downloads.html) and then, in the `vagrant` subdirectory, run `vagrant up`. MI-LXC is then installed in `/root/mi-lxc` and already provisionned (no need to `create`, you can directly `start`).


Usage
-----


<!-- * `./mi-lxc.py addbridges     # Create required network bridges on the host` -->
* `./mi-lxc.py create         # Creates a master container and then clones it to create all the containers`
* `./mi-lxc.py start          # Start the generated infrastructure  (stop to stop it)`
* `./mi-lxc.py attach [user@]<name> [command]  # Executes [command] in the container <name> as user [user]. [command] and [user] are optional; if not specified, user is root and command is an interactive shell.`
* `./mi-lxc.py display [user@]<name> # X11 access to the container <name>. You can also specify a username at the end of the line (default: debian)`
* `./mi-lxc.py                # Usage and list of container names`
* `./mi-lxc.py destroy && ./mi-lxc.py destroymaster   # Destroys everything (master container and all linked containers)`


Known problems
--------------

If network seems to be stalled during provisioning (especially when you destroy then create), you can try `service lxc-net restart` before creating containers. It recreates the LXC bridge and seems to flush some problematic caches (ARP ?).

# How to extend

The topology is described in `setup.json` and the address space in `MI-IANA.txt`. You can either extend an existing AS (typically, Target) or create a new AS. In this second case, you can duplicate Target and then connect it to some transit operator under a new AS number (all BGP-related configuration is specified in `setup.json`)

# License
This software is licensed under AGPLv3 : you can freely reuse it as long as you write you use it and you redistribute your modifications. Special licenses with (even) more liberties for public teaching activities can be discussed.
