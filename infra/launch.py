#!/usr/bin/python3

import lxc
import sys

master = "debian-stretch-xfce"
backbone = "lxc-infra-backbone"
firewall = "lxc-infra-firewall"

containers = [backbone, firewall]

def cloneAll():
    mastercontainer = lxc.Container(master)
    for container in containers:
        clone(container, mastercontainer)

def clone(container, mastercontainer):
    print("Cloning " + container + " from " + master)
    #if c.defined:
    #        print("Container already exists", file=sys.stderr)
    #        sys.exit(1)
    newclone = mastercontainer.clone(container,flags=lxc.LXC_CLONE_SNAPSHOT)


def destroyAll():
    for container in containers:
        destroy(container)

def destroy(container):
    print ("Destroying " + container)
    c = lxc.Container(container)
    c.destroy()


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("no argument given")
        sys.exit(1)


    command = sys.argv[1]

    if (command == "create"):
        cloneAll()
    elif (command == "destroy"):
        destroyAll()

    
