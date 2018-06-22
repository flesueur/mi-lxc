#!/usr/bin/python3

import lxc
import sys
import os

prefixc = "lxc-infra-"
prefixbr = "lxc"

# Containers
masterc = prefixc+"master"
backbonec = prefixc+"backbone"
firewallc = prefixc+"firewall"
homec = prefixc+"home"
hackerc = prefixc+"hacker"
dmzc = prefixc+"dmz"
commercialc = prefixc+"commercial"
filerc = prefixc+"filer"
containers = [backbonec, firewallc,homec,hackerc,dmzc,commercialc,filerc]

# Bridges
lxcbr = "lxcbr0"
lanbr = prefixbr+"lan"
wanbr = prefixbr+"wan"
dmzbr = prefixbr+"dmz"
bridges = [lanbr, wanbr, dmzbr]

# Container connections
nics = { backbonec: {'interfaces': [(lxcbr,'dhcp'), (wanbr,'10.0.0.1/24')],
                     'gateway':'dhcp'},
         homec: {'interfaces':[(wanbr,'10.0.0.3/24')],
                 'gateway':'10.0.0.1'},
         hackerc: {'interfaces':[(wanbr,'10.0.0.4/24')],
                   'gateway':'10.0.0.1'},
         firewallc: {'interfaces':[(wanbr,'10.0.0.2/24'), (lanbr,'192.168.0.1/24'), (dmzbr,'192.168.1.1/24')],
                     'gateway':'10.0.0.1'},
         dmzc: {'interfaces':[(dmzbr,'192.168.1.2/24')],
                'gateway':'192.168.1.1'},
         commercialc: {'interfaces':[(lanbr,'192.168.0.2/24')],
                        'gateway':'192.168.0.1'},
         filerc: {'interfaces':[(lanbr,'192.168.0.3/24')],
                  'gateway':'192.168.0.1'}
        }

def getGateway(ipmask):
    atoms = ipmask.split("/")[0].split('.')
    res = atoms[0]+"."+atoms[1]+"."+atoms[2]+".1"
    return res


#########################

def createMaster():
    print("Creating master")
    c = lxc.Container(masterc)
    if c.defined:
        print("Master container already exists, going on...", file=sys.stderr)
        return c

    if not c.create("download", lxc.LXC_CREATE_QUIET, {"dist": "debian",
                                                   "release": "stretch",
                                                   "arch": "amd64"}):
                                                   print("Failed to create the container rootfs", file=sys.stderr)
                                                   sys.exit(1)
    configure(c)
    provision(c)
    return c

# def destroyMaster():
#     c = lxc.Container(master)
#     if c.defined:
#         print("Destroying master...")
#         c.stop()
#         if not c.destroy():
#             print("Failed to destroy the master container", file=sys.stderr)

########################

def clone(container, mastercontainer):
    print("Cloning " + container + " from " + mastercontainer.name)
    newclone = mastercontainer.clone(container,flags=lxc.LXC_CLONE_SNAPSHOT)
    return newclone

def destroy(container):
    print ("Destroying " + container)
    c = lxc.Container(container)
    c.stop()
    if not c.destroy():
        print("Failed to destroy the container " + container, file=sys.stderr)


def configure(c):
    #c = lxc.Container(master)
    c.clear_config_item("lxc.network")
    #c.network.remove(0)
    c.network.add("veth")
    c.network[0].link = lxcbr
    c.network[0].flags = "up"
    c.append_config_item("lxc.mount.entry", "/tmp/.X11-unix tmp/.X11-unix none ro,bind,create=dir 0 0")
    filesdir=os.path.dirname(os.path.realpath(__file__))
    c.append_config_item("lxc.mount.entry", filesdir + "/files mnt/lxc none ro,bind,create=dir 0 0")
    c.save_config()

def provision(c):
    #c = lxc.Container(master)
    folder = c.name[len(prefixc):]
    c.start()
    if not c.get_ips(timeout=60):
        print("Container seems to have failed to start (no IP)")
        sys.exit(1)
    c.attach_wait(lxc.attach_run_command, ["bash", "/mnt/lxc/"+folder+"/provision.sh"])
    c.stop()

def configNet(c):
    c.clear_config_item("lxc.network")
    cnics = nics[c.name]['interfaces']
    print("Configuring NICs of " + c.name + " to " + str(cnics))
    c.clear_config_item("lxc.network")
    i=0
    for cnic in cnics:
        k = cnic[0]
        v = cnic[1]
        c.network.add("veth")
        c.network[i].link = k
        if not (v == 'dhcp'):
            c.append_config_item("lxc.network."+str(i)+".ipv4", v)
            if (getGateway(v) == nics[c.name]['gateway']):
                c.network[i].ipv4_gateway = getGateway(v)
        #c.network[i].script_up = "upscript"
        c.network[i].flags = "up"
        i+=1
    c.save_config()


############################


def createInfra():
    mastercontainer = createMaster()
    for container in containers:
        newclone = clone(container, mastercontainer)
        provision(newclone)
        configNet(newclone)

def destroyInfra():
    for container in containers:
        destroy(container)
#    destroy(masterc)

def startInfra():
    for container in containers:
        print ("Starting " + container)
        c = lxc.Container(container)
        c.start()

def stopInfra():
    for container in containers:
        print ("Stopping " + container)
        c = lxc.Container(container)
        c.stop()

def display(c):
    #c.attach(lxc.attach_run_command, ["Xnest", "-sss", "-name", "Xnest", "-display", ":0", ":1"])
    displaynum = containers.index(c.name)+2
    print("Using display " + str(displaynum))
    os.system("xhost local:")
    c.attach(lxc.attach_run_command, ["/bin/su", "-l", "-c",
                                        "killall Xnest ; \
                                        Xnest -sss -name \"Xnest " +c.name+ "\" -display :0 :"+str(displaynum)+" & \
                                        export DISPLAY=:"+str(displaynum)+" ; \
                                        while ! `setxkbmap fr` ; do sleep 1 ; done ; \
                                        xfce4-session &  \
                                        sleep 1 && setxkbmap fr",
                                        "debian"])

#################

def createBridges():
    print("Creating bridges")
    for bridge in bridges :
        os.system("brctl addbr " + bridge)
        os.system("ifconfig " + bridge + " up")
        os.system("iptables -A FORWARD -i " + bridge + " -o " + bridge + " -j ACCEPT")
        os.system("echo 1 > /proc/sys/net/ipv4/ip_forward")


def deleteBridges():
    print("Deleting bridges")
    for bridge in bridges:
        os.system("ifconfig " + bridge + " down")
        os.system("brctl delbr " + bridge)
        os.system("echo 0 > /proc/sys/net/ipv4/ip_forward")
        os.system("iptables -D FORWARD -i " + bridge + " -o " + bridge + " -j ACCEPT")


###################

def usage():
    print("No argument given, usage with create, destroy, createmaster, destroymaster, addbridges, delbridges, start, stop, attach <name>, display <name>\nNames are ", end='')
    for container in containers:
        print (container[len(prefixc):],end=', ')
    print("\n")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        usage()
        sys.exit(1)


    command = sys.argv[1]

    if (command == "create"):
        createInfra()
    elif (command == "destroy"):
        destroyInfra()
    elif (command == "start"):
        startInfra()
    elif (command == "stop"):
        stopInfra()
    elif (command == "attach"):
        lxc.Container(prefixc+sys.argv[2]).attach_wait(lxc.attach_run_shell)
    elif (command == "display"):
        display(lxc.Container(prefixc+sys.argv[2]))
    elif (command == "createmaster"):
        createMaster()
    elif (command == "destroymaster"):
        destroy(masterc)
    elif (command == "addbridges"):
        createBridges()
    elif (command == "delbridges"):
        deleteBridges()
    else:
        usage()
