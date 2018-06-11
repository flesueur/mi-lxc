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

The 'debian-stretch-xfce' directory allows to create a single container and is included for illustration. MI-LXC sits in the 'infra' directory. The 'files' subdirectory contains files and scripts to provision the containers. The 'launch.py' script is used in the following way (as *root*, since it manipulates bridges and lxc commands)

* ./launch.py addbridges     # Create required network bridges on the host
* ./launch.py create         # Creates a master container and then clones it to create all the containers
* ./launch.py start          # Start the generated infrastructure  (stop to stop it)
* ./launch.py attach <name>  # Shell access to the container <name>
* ./launch.py display <name> # X11 access to the container <name>
* ./launch.py                # Usage and list of container names


# License
This software is licensed under AGPLv3 : you can freely reuse it as long as you write you use it and you redistribute your modifications. Special licenses with (even) more liberties for public teaching activities can be discussed.
