# How to install MI-LXC

## Installation sur Linux

On Debian (Strech/Buster), you need lxc, python3-lxc, dnsmasq-base, bridge-utils, python3-pil and python3-pygraphviz (`apt-get install lxc python3-lxc dnsmasq-base bridge-utils python3-pil python3-pygraphviz`) and then to enable networking in the LXC configuration (`USE_LXC_BRIDGE="true"` in `/etc/default/lxc-net`). Finally, you need to restart LXC networking (`service lxc-net restart`).

On Ubuntu Bionic (2018.04 LTS), you first need to enable the multiverse repository. Then you need to install lxc-utils, python3-lxc dnsmasq-base, python3-pil and python3-pygraphviz (`apt-get install lxc-utils python3-lxc dnsmasq-base python3-pil python3-pygraphviz`). You may need to restart lxc-net or apparmor. If you are using Ubuntu as a live CD, you need some mounted storage (4GB should be ok) and then to configure LXC to use this space : create the `/etc/lxc/lxc.conf` with the content `lxc.lxcpath=/mnt` (location where you mounted your storage)

On Kali 2018.2, you need lxc (`apt-get install lxc`) and then to enable networking in the LXC configuration (`USE_LXC_BRIDGE="true"` in `/etc/default/lxc-net`). Finally, you need to restart LXC and AppArmor (`service lxc restart && service apparmor restart`). If you are using Kali as a live CD, you need some mounted storage (4GB should be ok) and then to configure LXC to use this space : create the `/etc/lxc/lxc.conf` with the content `lxc.lxcpath=/mnt` (location where you mounted your storage)

On Arch Linux, you need to downgrade LXC to LXC 2.0.7 (it should now work with LXC 3, reports welcome), then to install python3-lxc from the official lxc github. You also need dnsmasq and python-graphviz. Rest of the configuration is quite similar (network configuration, service restart, etc.)

> Optionally, you can:
> * install `apt-cacher-ng` on your host (port 3142) to speed up the creation of the containers. This proxy is detected in [masters/buster/detect_proxy.sh](https://github.com/flesueur/mi-lxc/blob/master/masters/buster/detect_proxy.sh).
> * install the bash autocompletion script `milxc-completion.bash`, either by sourcing it in your current shell (`source milxc-completion.bash`) or by copying it in `/etc/bash_completion.d/`

## Installation sur Windows/MacOS/Linux (en utilisant Vagrant)

The `vagrant` subdirectory contains a `Vagrantfile` suited to generate a VirtualBox VM running MI-LXC inside. You need to install [Vagrant](https://www.vagrantup.com/downloads.html) and then, in the `vagrant` subdirectory, run `vagrant up`. You can then login as root/root. MI-LXC is installed in `/root/mi-lxc` and already provisionned (no need to `create`, you can directly `start`).


## Qu'est ce qui est fait avec les permissions de root ?

* Manipulation des conteneurs LXC (pas encore d'utilisation non privilégiée de LXC)
* Gestion des ponts ethernet virtuels avec `brctl`, `ifconfig` et `iptables` (dans mi-lxc.py:createBridges() et mi-lxc.py:deleteBridges(), autour de [ligne 324](https://github.com/flesueur/mi-lxc/blob/master/mi-lxc.py#L324))
* Augmentation de fs.inotify.max_queued_events, fs.inotify.max_user_instances et fs.inotify.max_user_watches par `sysctl` (in mi-lxc.py:increaseInotify(), environ [ligne 278](https://github.com/flesueur/mi-lxc/blob/master/mi-lxc.py#L278))

Ce n'est pas idéal mais c'est actuellement nécessaire. Une [issue](https://github.com/flesueur/mi-lxc/issues/9) est ouverte sur le sujet mais ce n'est pas prévu actuellement.
