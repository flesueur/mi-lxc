# MI-LXC Tutorial

[![fr](https://img.shields.io/badge/lang-fr-informational)](https://github.com/flesueur/mi-lxc/blob/master/doc/TUTORIAL.fr.md)


I --- Process of this tutorial
================================

MI-LXC is a framework for designing network/system architectures in which learners can confront themselves with a realistic environment. This tutorial is divided into 3 parts corresponding to the different aspects of MI-LXC:

* **Learner - Learning how the internet works and security issues**. It is about using a previously specified infrastructure (topology, software installed and configured on all containers). On this infrastructure, he will be able to discover how the Internet works, the system interconnections between the different AS, the attack and defense schemes. In this posture, it is necessary to launch MI-LXC (`./mi-lxc.py start`) and then to connect to different containers of this infrastructure (`./mi-lxc.py display isp-a-hacker`, `./mi-lxc.py attach target-dmz`, etc.)
* **Designer - Specification of an infrastructure**. This involves specifying an infrastructure:
  * The topology (host names, IPv4/IPv6 addresses, network bridges) (`global.json` and `groups/*/local.json` for each AS)
  * Installation and configuration of each system (bash scripts `provision.sh` for each host groups/\*/\*/provision.sh)
  * Setting up templates to share common aspects (bash scripts `provision.sh` for host templates and `local.json` for AS templates, in the `templates` folder)
  * The creation of masters to use other distributions (`masters` folder)
* **Developer - The development of the MI-LXC engine**. It is about providing new features in the MI-LXC framework, in the python code `mi-lxc.py` as well as the `backends/` folder. For example, the improvement of the visualization, the configuration management or the support of other host backends than LXC (Linux only) or Dynamips (cisco routers), for example adding Vagrant/Virtualbox to be able to generate Windows machines.


II --- Before getting started
===============================

1. A [general presentation (in English)](https://www.youtube.com/watch?v=waCsmE7BeZs) at ETACS 2021 (video)
2. A [video tutorial (in French)](https://mi-lxc.citi-lab.fr/data/media/tuto1.mp4) to get started
3. A functional installation:
  * A ready-to-use VirtualBox VM (about 5GB to download and then an 11GB VM): [here](https://mi-lxc.citi-lab.fr/data/milxc-debian-amd64-1.3.1.ova). You have to connect to it as root/root then, with a terminal:
    * `cd mi-lxc`
    * `./mi-lxc.py start`
    * `./mi-lxc.py display isp-a-hacker`
  * The creation of the VM via Vagrant (VM of about 11GO, 15-30 minutes for the creation): [here](INSTALL.md#installation-on-windowsmacoslinux-using-vagrant). LXC containers are automatically generated when the VM is created. Once Vagrant is finished, you have to connect to the VM as root/root and then, with a terminal :
    * `cd mi-lxc`
    * `./mi-lxc.py start`
    * `./mi-lxc.py display isp-a-hacker`
  * The direct installation under Linux (15-30 minutes for the creation): [here](INSTALL.md#installation-on-linux). LXC containers will be installed on the host:
    * `git clone https://github.com/flesueur/mi-lxc.git`
    * `cd mi-lxc`
    * `./mi-lxc.py create`
    * `./mi-lxc.py start`
    * `./mi-lxc.py display isp-a-hacker`

> To remove a mouse stuck in a Xephyr, Ctrl+Shift



III --- Learner - Learning how the internet works and security issues
=========================================================================================

We will see 2 aspects on the learner side:
* A BGP attack
* A network segmentation (redistribution)

These 2 elements allow a first overview of the functionalities of MI-LXC and can be completed with the TP subjects quoted at the beginning of [README](https://github.com/flesueur/mi-lxc#readme).

III.1 --- BGP attacks
-----------------------

(Extract from [TP CA](https://github.com/flesueur/csc/blob/master/tp1-https.md), translated here in English)

You can display a network map with `./mi-lxc.py print`.

To connect to a machine:

* `./mi-lxc.py display isp-a-home` : to display the desktop of the isp-a-home machine which will be your web browser in this tutorial (as a debian user)
* `./mi-lxc.py attach target-dmz` : to get a shell on the target-dmz machine which hosts the web server to secure (as root user)

All machines have the following two accounts: debian/debian and root/root (login/password).

From the isp-a-home machine, open a browser to connect to `http://www.target.milxc`. You get to a Dokuwiki page, which is the expected page hosted on target-dmz.

We are now going to attack from the ecorp AS this unsecured communication between isp-a-home and target-dmz. The objective is that the browser, when it wants to connect to the URL `http://www.target.milxc`, actually arrives on the ecorp-infra machine. So this BGP attack consists in rerouting packets to the target AS to the ecorp AS (an [example of real BGP hijacking in 2020](https://radar.qrator.net/blog/as1221-hijacking-266asns)):
* On the ecorp-router machine: take an IP from the target AS, which will automatically trigger the announcement of this network in BGP (`ifconfig eth1:0 100.80.1.1 netmask 255.255.255.0`)
* On the ecorp-infra machine: take the IP of `www.target.milxc` (`ifconfig eth0:0 100.80.1.2 netmask 255.255.255.0`)

We see a case of a BGP attack: a user on isp-a-home who, when typing the URL `www.target.milxc`, actually arrives at a service other than the one expected (here, the ecorp-infra machine). Reset the system to proper working order to continue (disable the eth1:0 interface on ecorp-router `ifconfig eth1:0 down`).

> The site [Is BGP safe yet?](https://isbgpsafeyet.com/), operated by Cloudflare, describes these BGP attacks very clearly, and gives a summary of the current state of BGP security and the deployment of RPKI, a countermeasure to these BGP attacks.

III.2 --- Network segmentation (redistribution)
-------------------------------------------------

(Extract from [TP Firewall](https://github.com/flesueur/srs/blob/master/tp2-firewall.md), translated here in English)

NoWe will segment the target network to deploy a firewall between distinct zones. The segmentation will take place around the `target-router` machine. Initially, the internal network is completely flat, connected to the target-lan bridge and in the 100.80.0.1/16 address space. We will simply add a DMZ on this flat network (a new network bridge and a redrawing of the address space). You will need to proceed in two steps:

* Segment the "target" network (**Please take the time to watch the [video tuto](https://mi-lxc.citi-lab.fr/data/media/segmentation_milxc.mp4) !!! (in french)**) :
	* Edit `global.json` (in the mi-lxc folder) to specify the interfaces on the router, in the "target" section. We need to add a target-dmz bridge (the name must start with "target-") and split the 100.80.0.0/16 space: 100.80.0.0/24 on the pre-existing target-lan bridge (so specify an IPv4 of 100.80.0.1/24), 100.80.1.0/24 on the new target-dmz bridge (so specify an IPv4 of 100.80.1.1/24). Finally, you have to add the eth2 interface to the `asdev` list defined above (with ';' separating interfaces, there are examples around)
	* Edit `groups/target/local.json` to modify the interface addresses and bridges of the internal machines (be careful, for a bridge previously named "target-dmz", you just have to write "dmz" here, the "target-" part is added automatically). You must:
      * Put the dmz machine on the dmz bridge, change its address to 100.80.1.2/24, update its gatewayv4 (100.80.1.1) just below
      * For all other machines, update the netmask to /24
	* Run `./mi-lxc.py print` to view the redefined topology
	* Run `./mi-lxc.py stop && ./mi-lxc.py renet && ./mi-lxc.py start` to update the deployed infrastructure
* Implement iptables commands on the target-router machine (in the FORWARD chain) to allow the necessary routing between interfaces (eth0 is the outgoing interface, eth1 is on the target-lan bridge and eth2 is the new interface on the target-dmz bridge). If possible in a script (which cleans up the rules at the beginning), in case of an error.

> `renet` is a quick operation that avoids the need to delete and re-generate the infrastructure. It updates IPs and some configurations. Typically, we will see the provision.sh script in the following, renet runs instead the renet.sh script (present in some directories).

> The MI-LXC tree and the json files handled here are described [here](https://github.com/flesueur/mi-lxc#how-to-extend).


IV --- Designer - Specification of an infrastructure
======================================================

MI-LXC allows the rapid prototyping of an infrastructure. The idea is to enrich the existing core rather than to start from scratch. Typically, the backbone, the DNS infrastructure and a minimum of access services are intended to allow the rapid bootstrapping of a new AS (so at least the transit-a, transit-b, isp-a, root-o, root-p, opendns, milxc groups, described in DETAILS.md). In this tutorial we will add an AS to the existing infrastructure.

The procedure will be as follows:
* Declare an AS number, an IP address range and a domain name for this new organization
* Create this minimalist AS in MI-LXC
* Add another host to this AS
* Modify this new host
* Register it in DNS
* Explore the template mechanism

IV.1 --- Declaration of a new AS
----------------------------------

The file `doc/MI-IANA.en.txt` represents the IANA directory. Here you can find a free AS number and a free IP range. The routable IPv4s are allocated in the 100.64.0.0/10 space (reserved for CG-NAT and therefore normally free of local conflicts).

You can also take advantage of this to plan a domain name in .milxc


IV.2 --- Creation this AS in MI-LXC
-------------------------------------

An AS is represented by a group of hosts. The first step is to declare this new group in the global topology file `global.json`. Add a simple group to it from an existing template. For example, the existing group "milxc" is defined as follows:

```
"milxc": {
  "templates":[{"template":"as-bgp", "asn":"8", "asdev":"eth1", "neighbors4":"100.64.0.1 as 30","neighbors6":"2001:db8:b000::1 as 30",
  "interfaces":[
    {"bridge":"transit-a", "ipv4":"100.64.0.40/24", "ipv6":"2001:db8:b000::40/48"},
    {"bridge":"milxc-lan", "ipv4":"100.100.20.1/24", "ipv6":"2001:db8:a020::1/48"}
  ]
}]}
```

The _template_ field describes the template of the group, here it will also be an as-bgp. The _asn, asdev, neighbors4, neighbors6_ and _interfaces_ fields must be adjusted:
* _asn_ is the AS number, as declared in `MI-IANA.en.txt`
* _asdev_ is the network interface that will be connected to the organization's _internal_ network (the one that has the IPs linked to the AS, this will be eth1 in the example)
* _neighbors4_ are the BGP4 peers for IPv4 routing (in the format _IP\_du\_pair as ASN\_du\_pair_)
* _neighbors6_ are the BGP6 peers for IPv6 routing (optional, in _IP\_du\_pair as ASN\_du\_pair_ format)
* _interfaces_ describes the network interfaces of the router of this AS (despite the misleading indentation, it is indeed a parameter of the as-bgp template). For each interface, you must specify its bridge, ipv4 and ipv6 (optional) statically here. In this example:
  * _transit-a_ is the bridge operated by the operator Transit-A, connecting to it allows to go to the other AS, it is necessary to use a free IP in its network 100.64.0.40/24 and this interface will be the external interface _eth0_
  * _milxc-lan_ is the internal bridge of this organization, it is associated with an IP of its AS. Its name must **imperatively** start with the name of the group + "-", here "milxc-", and not be too long (max 15 characters, kernel level network interface naming constraint)

To integrate your new AS, you will have to choose which transit point to connect it to and with which IP. A `./mi-lxc.py print` gives you an overview of the connections and IPs used (as long as the JSON is well formed...). You also have to declare this new peer on the other side of the BGP tunnel (here, this router of the group "milxc" is for example listed in the BGP peers of the group "transit-a").

Once this is defined, a `./mi-lxc.py print` to check the topology, then `./mi-lxc.py create` will create the router machine associated with this AS (it will be an Alpine Linux). The create operation is lazy, it only creates non-existent containers and will therefore be fast.

> **DANGER ZONE** We will destroy one container and only one. If you make a wrong manipulation, you risk destroying the whole infrastructure and then taking 15 minutes to rebuild everything, that's not the goal. So specify well the name of the container to destroy and, if you are in a VM, it could be the moment to make a snapshot...

At this point, however, the BGP peer (the other end of the BGP tunnel updated in the JSON, e.g. the transit-a-router container) does not yet know about this new router. It needs to be destroyed and re-generated: `./mi-lxc.py destroy transit-a-router` (_only_ destroys the transit-a-router container) and then `./mi-lxc.py create` to re-generate it. (eventually, a renet could be enough, but it is not currently implemented for AlpineLinux BGP routers)

Finally, we can do a `./mi-lxc.py start` and check the good start.

> Warning, for IP and route management reasons, surprisingly, there is no easy way for the router to initiate communications itself. That is, if everything works well it will be started, will have good routing tables, but still will not be able to ping outside the forwarder's subnet. This is the expected behavior and therefore checking the router's connectivity cannot be done like that. We will then see how to check this from an internal station and we will use, on the router or its BGP neighbors, the `birdc show route all` and `birdc show protocols` commands to inspect the routing tables and verify the establishment of BGP sessions.

IV.3 --- Adding a host in the new AS
--------------------------------------

We will now add a new host to this AS. If the group was named "acme" in global.json, we need to create the `groups/acme` folder to host it. In this folder we will have:
* a `local.json` file which describes the internal topology of the group
* a sub-folder for provisioning each of these hosts

An example of a minimal `local.json` (groups/gozilla/local.json) :
```
{
  "comment":"Gozilla AS",
  "containers": {
    "infra":
        {"container":"infra",
          "interfaces":[
            {"bridge":"lan", "ipv4":"100.83.0.2/16", "ipv6":"2001:db8:83::2/48"}
          ],
          "gatewayv4":"100.83.0.1",
          "gatewayv6":"2001:db8:83::1",
          "templates":[{"template":"nodhcp", "domain":"gozilla.milxc", "ns":"100.100.100.100"}]}
  }
}
```

This JSON defines:
* that there is a container called infra (and that it will therefore be provisioned in the infra subfolder)
* that it has a network interface connected to the _gozilla-lan_ bridge with the specified IPs (the prefix _groupname-_ is automatically added to the name written in this JSON)
* that its IPv4 gateway is 100.83.0.1
* that it uses a template (we will detail this later) that disables DHCP and sets the domain and DNS server

To provision this container, create the sub-folder _infra_ and write a _provision.sh_ script of the type:
```
#!/bin/bash
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

# do something visible
```
* The shebang is mandatory at the beginning and will be used (and a python script, as long as it is called provision.sh, probably works)
* The `set -e` is very strongly recommended (it allows to stop the script as soon as a command returns an error code, and to return an error code in its turn. Without this `set -e`, the execution continues and the result may surprise you...)
* the _$MILXCGUARD_ variable is automatically set at runtime in MI-LXC, checking it prevents a script from running on its own machine by mistake (ouch!)
* In general, setting the correct directory helps to avoid multiple mess-ups. This folder can contain files to be copied to the new container, etc.

As a good practice in terms of maintenance, you should favour file modifications (at the cost of sed, >>, etc.) rather than pure and simple overwriting. Example of a kivabian sed: `sed -i -e 's/Allow from .*/Allow from All/' /etc/apache2/conf-available/dokuwiki.conf`. You can also find in groups/target/ldap/provision.sh the manipulations allowing to preconfigure (_preseed_) the Debian packages installations.

Once all this is done, we can do `./mi-lxc.py print` to check that the JSON is well formed and that the topology is correct. A `./mi-lxc.py create` will create this container, then `./mi-lxc.py start` will run it (no need to have stopped the others first).


IV.4 --- Modification of this host
------------------------------------

Now that this host is created, we will modify it. Let's add:
* using another template, for example `mailclient` (it is defined in templates/hosts/debian/mailclient, just name it mailclient in the local.json). This template has 4 parameters, you can see a use of it in groups/target/local.json . Configure it with fictitious values (just put 'debian' as value for login, this is the name of the local Linux account that will be configured for mail and this account must already exist. The debian account exists and is the one used by default for the display command)
* another action in the provision.sh


To update this container with these changes without rebuilding everything, you need to:
* `./mi-lxc.py destroy acme-moncontainer` # destroy _only_ the acme-moncontainer
* `./mi-lxc.py create` # rebuild only this missing container
* `./mi-lxc.py start` # restarts this new container
* `./mi-lxc.py display acme-moncontainer` # see that claws-mail has been configured by your settings



IV.5 --- Registration in the DNS
----------------------------------

This host has a public IP and you have provided a domain name, acme.milxc (the internal TLD is .milxc). To have a working DNS entry for acme.milxc you will obviously have to set up a DNS server for this zone (example in groups/isp-a/infra), which we will not do here. You also have to register this DNS server on the server that manages .milxc.

This is done in groups/milxc/ns/provision.sh, just reproduce the example of isp-a.milxc. Then, `./mi-lxc.py destroy milxc-ns && ./mi-lxc.py create`


IV.6 --- Creation a new template
----------------------------------

MI-LXC provides two template mechanisms:
* group templates, defined in `templates/groups/`. Here we used as-bgp for example, which creates an AS edge router with Alpine Linux. The as-bgp-debian template produces the same functionality but with a Debian router
* host templates, defined in `templates/hosts/<family>/`. When deriving from a Debian master (which is the default, masters are defined in global.json), the templates are looked up in `templates/hosts/debian/`

We'll add a host template for greeting in .bashrc, which is identical for many machines. Create a subfolder for this template, a provision.sh script similar to that of a host, and then call this template in the previously created host.


V --- Developer - The development of the MI-LXC engine
======================================================

Finally, we'll explore the framework's Python code a bit, looking at the path to add a runtime backend. Today, MI-LXC supports LXC container execution and Cisco router emulation (dynamips), both of which are defined in the backends/ folder.

We will see how we could add a Vagrant/VirtualBox backend to virtualize Windows hosts for example. First of all, we need to create a new master in `global.json`. For example:
```
{
"backend":"lxc",
"template":"download",
"parameters":{"dist": "debian", "release": "buster", "arch": "amd64", "no-validate": "true"},
"family":"debian",
"name":"buster"
},
```
specifies that :
* The name of the backend to be used is "lxc" (to be changed, then)
* The family field indicates that the templates will be searched in the `templates/hosts/<family>` folder
* The name field names the template
* The rest (template, parameters here) is free and will be read by the specified backend

So create a new master with another non-existent backend. Then, `./mi-lxc.py print` will tell you the line in `mi-lxc.py` where to add the case of this new backend (in getMasters2()). Based on the 2 existing cases, you will have to add a case and create an object of a new type, to be defined in the backends folder. You can start from backends/HostBackend to have an empty skeleton and thus an idea of the functions that will be filled.

The idea in this tutorial is, of course, not to write this new backend, but it should :
* propose 2 classes : one for the masters, one for the hosts
* the LXC and Dynamips examples show how to mutualize a part of these two classes in a common class. The file LxcBackend.py can be used for the beginning of many functions.
* it will be necessary to add the `master:TheNewMaster` parameter to the hosts that should use this new master
* adding it to the hosts will bring up a second condition (in getHosts()) in which you have to add the case of this backend
* YOLO!
