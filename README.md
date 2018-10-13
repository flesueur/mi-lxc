# MI-LXC : Mini-Internet using LXC

MI-LXC uses LXC to simulate a small-scale internet-like environment. I use this environment for (infosec) practical work (intrusion, firewall, IDS, etc.). The small memory footprint of LXC combined with differential images allows to run it on modest hardware.

It is based on the infrastructure-as-code principle, these scripts programmatically generate the target environment.

# Features and composition

Features :

* Containers run up-to-date Debian Stretch
* The infrastructure-as-code principle allows for easy management, deployment and evolution along time
* The infrastructure is built by final users on their own PC
* Every container also have access to the real internet (software installation)
* Containers provide shell access as well as X11 interface

The network is composed of :

* a WAN (a PC used by the hacker and a random PC)
* a DMZ (a server running HTTP, mail and DNS service for the company)
* a LAN (a few PC on a LAN, among which an internal server)
* a firewall
* a backbone container (running mail and DNS service for WAN PC and routing to the real internet)


# How to use it

The 'debian-stretch-xfce' directory allows to create a single container and is included for illustration only. The `files` subdirectory contains files and scripts to provision the containers. The `launch.py` script is used in the following way (as *root*, since it manipulates bridges and lxc commands)

## Prerequisites

On Debian Strech, you need lxc (`apt-get install lxc`) and then to enable networking in the LXC configuration (`USE_LXC_BRIDGE="true"` in `/etc/default/lxc-net`). Finally, you need to restart LXC networking (`service lxc-net restart`).

On Ubuntu Bionic (2018.04 LTS), you first need to enable the multiverse repository. Then you need to install lxc-utils and python3-lxc (`apt-get install lxc-utils python3-lxc`). You may need to restart lxc-net or apparmor. If you are using Ubuntu as a live CD, you need some mounted storage (4GB should be ok) and then to configure LXC to use this space : create the `/etc/lxc/lxc.conf` with the content `lxc.lxcpath=/mnt` (location where you mounted your storage)

On Kali 2018.2, you need lxc (`apt-get install lxc`) and then to enable networking in the LXC configuration (`USE_LXC_BRIDGE="true"` in `/etc/default/lxc-net`). Finally, you need to restart LXC and AppArmor (`service lxc restart && service apparmor restart`). If you are using Kali as a live CD, you need some mounted storage (4GB should be ok) and then to configure LXC to use this space : create the `/etc/lxc/lxc.conf` with the content `lxc.lxcpath=/mnt` (location where you mounted your storage)

On Arch Linux, you need to downgrade LXC to LXC 2.0.7 (it should now work with LXC 3, reports welcome), then to install python3-lxc from the official lxc github. You also need dnsmasq. Rest of the configuration is quite similar (network configuration, service restart, etc.)

Usage
-----


<!-- * `./mi-lxc.py addbridges     # Create required network bridges on the host` -->
* `./mi-lxc.py create         # Creates a master container and then clones it to create all the containers`
* `./mi-lxc.py start          # Start the generated infrastructure  (stop to stop it)`
* `./mi-lxc.py attach <name>  # Shell access to the container <name>`
* `./mi-lxc.py display <name> # X11 access to the container <name>. You can also specify a username at the end of the line (default: debian)`
* `./mi-lxc.py                # Usage and list of container names`

Known problems
--------------

If you're on INSA-Lyon's eduroam, there is a blocked port which prevents the PGP integrity verification of the downloaded LXC template. In that case, creation of the master container will fail (timeout). To debug it, you can try `lxc-create -t download -n lxc-test -- -d debian -r stretch -a amd64`: if it does not work then you need the following workaround (to delete the test container : `lxc-destroy -n lxc-test`). You can execute `export DOWNLOAD_KEYSERVER="hkp://pgp.mit.edu:80"` (you can also try `̀hkp://p80.pool.sks-keyservers.net:80`) at the beginning of your session to resolve it. You also need a large thermos of coffee, of course.

# License
This software is licensed under AGPLv3 : you can freely reuse it as long as you write you use it and you redistribute your modifications. Special licenses with (even) more liberties for public teaching activities can be discussed.
