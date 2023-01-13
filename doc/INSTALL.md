# How to install MI-LXC

## Installation on Linux

First, you need to [install SNSTER](https://framagit.org/flesueur/snster/-/blob/main/doc/INSTALL.md#installation-on-linux), the framework used by MI-LXC.

Then, to populate and use MI-LXC, you need to go in the `mi-lxc/topology` directory and run `snster create`.

## Installation on Windows/MacOS/Linux (using Vagrant)

The `vagrant` subdirectory contains a `Vagrantfile` suited to generate a VirtualBox VM running MI-LXC inside. You need to install [Vagrant](https://www.vagrantup.com/downloads.html) and then, in the `vagrant` subdirectory, run `vagrant up`. You can then login as root/root. MI-LXC is installed in `/root/mi-lxc` and already provisionned (no need to `create`, you can directly `start`).


## What is done with root permissions ?

* Manipulation of LXC containers (no unprivileged LXC usage yet)
* Management of virtual ethernet bridges with `brctl`, `ifconfig` and `iptables` (in mi-lxc.py:createBridges() and mi-lxc.py:deleteBridges(), around [line 324](https://github.com/flesueur/mi-lxc/blob/master/mi-lxc.py#L324))
* Increase of fs.inotify.max_queued_events, fs.inotify.max_user_instances and fs.inotify.max_user_watches through `sysctl` (in mi-lxc.py:increaseInotify(), around [line 278](https://github.com/flesueur/mi-lxc/blob/master/mi-lxc.py#L278))

This is not ideal but is currently needed. An [issue](https://github.com/flesueur/mi-lxc/issues/9) is opened on the topic but it is not currently planned.
