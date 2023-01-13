# How to install MI-LXC

## Installation sur Linux

First, you need to [install SNSTER](https://framagit.org/flesueur/snster/-/blob/main/doc/INSTALL.md#installation-on-linux), the framework used by MI-LXC.

Then, to populate and use MI-LXC, you need to go in the `mi-lxc/topology` directory and run `snster create`.

## Installation sur Windows/MacOS/Linux (en utilisant Vagrant)

The `vagrant` subdirectory contains a `Vagrantfile` suited to generate a VirtualBox VM running MI-LXC inside. You need to install [Vagrant](https://www.vagrantup.com/downloads.html) and then, in the `vagrant` subdirectory, run `vagrant up`. You can then login as root/root. MI-LXC is installed in `/root/mi-lxc` and already provisionned (no need to `create`, you can directly `start`).


## Qu'est ce qui est fait avec les permissions de root ?

* Manipulation des conteneurs LXC (pas encore d'utilisation non privilégiée de LXC)
* Gestion des ponts ethernet virtuels avec `brctl`, `ifconfig` et `iptables` (dans mi-lxc.py:createBridges() et mi-lxc.py:deleteBridges(), autour de [ligne 324](https://github.com/flesueur/mi-lxc/blob/master/mi-lxc.py#L324))
* Augmentation de fs.inotify.max_queued_events, fs.inotify.max_user_instances et fs.inotify.max_user_watches par `sysctl` (in mi-lxc.py:increaseInotify(), environ [ligne 278](https://github.com/flesueur/mi-lxc/blob/master/mi-lxc.py#L278))

Ce n'est pas idéal mais c'est actuellement nécessaire. Une [issue](https://github.com/flesueur/mi-lxc/issues/9) est ouverte sur le sujet mais ce n'est pas prévu actuellement.
