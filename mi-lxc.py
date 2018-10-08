#!/usr/bin/python3

import lxc
import sys
import os
import json
import argparse

def getGlobals(data):
    global lxcbr,prefixc,prefixbr
    lxcbr = data["nat-bridge"]
    prefixc = data["prefix-containers"]
    prefixbr = data["prefix-bridges"]
    return

def getContainers(data):
    global containers,masterc
    masterc = prefixc + "master"
    for container in data["containers"]:
        containers.append(prefixc+container["container"])
    return

def getBridges(data):
    global bridges
    for container in data["containers"]:
        for interface in container["interfaces"]:
            if interface["bridge"] != "nat-bridge":
                bridges.add(prefixbr+interface["bridge"])
    #for bridge in data["bridges"]:
    #    bridges.add(prefixbr+bridge["bridge"])
    return

def getNics(data):
    global nics
    for container in data["containers"]:
        cname = prefixc+container["container"]
        gateway = container["gateway"]
        interfaces = []
        for interface in container["interfaces"]:
            iface = interface["bridge"]
            if iface == "nat-bridge":
                iface = lxcbr
            else:
                iface = prefixbr + iface
            interfaces.append((iface, interface["address"]))
        nics[cname] = {'gateway' : container["gateway"], 'interfaces':interfaces}
    return

def getMITemplates(data):
    global mitemplates
    for container in data["containers"]:
        cname = prefixc+container["container"]
        templates = []
        if "templates" in container.keys():
            #for template in container["templates"]:
            #    templates.append(template["template"])
            mitemplates[cname] = container["templates"]
    return


config = "setup.json"

prefixc = "lxc-infra-"
prefixbr = "lxc"
lxcbr = "lxcbr0"

# Containers
masterc = ""
containers = []

# Bridges
bridges = set()

nics = {}

mitemplates = {}

def getGateway(ipmask):
    atoms = ipmask.split("/")[0].split('.')
    mask = ipmask.split("/")[1]
    if (mask == "24"):
        res = atoms[0]+"."+atoms[1]+"."+atoms[2]+".1"
    elif (mask == "16"):
        res = atoms[0]+"."+atoms[1]+".0.1"
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
    try:  # AppArmor is installed and must be configured
        c.get_config_item("lxc.apparmor.profile")   # may be aa_profile sometimes ?
        c.append_config_item("lxc.apparmor.profile", "unconfined")
    except:  # AppArmor is not installed and must not be configured
        pass
    try:  # AppArmor is installed and must be configured
        c.get_config_item("lxc.aa_profile")   # may be aa_profile sometimes ?
        c.append_config_item("lxc.aa_profile", "unconfined")
    except:  # AppArmor is not installed and must not be configured
        pass

    c.save_config()

def provision(c):
    #c = lxc.Container(master)
    folder = c.name[len(prefixc):]
    c.start()
    if not c.get_ips(timeout=60):
        print("Container seems to have failed to start (no IP)")
        sys.exit(1)

    if c.name in mitemplates.keys():
        for template in mitemplates[c.name]:
            if (template["template"] != "internal"):
                args = []
                for arg in template:
                    args.append(arg+"="+template[arg])
                c.attach_wait(lxc.attach_run_command, ["env"]+args+["bash", "/mnt/lxc/templates/"+template["template"]+"/provision.sh"], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)

    c.attach_wait(lxc.attach_run_command, ["bash", "/mnt/lxc/"+folder+"/provision.sh"], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)

    if c.name in mitemplates.keys():
        for template in mitemplates[c.name]:
            if (template["template"] == "internal"):
                args = []
                for arg in template:
                    args.append(arg+"="+template[arg])
                c.attach_wait(lxc.attach_run_command, ["env"]+args+["bash", "/mnt/lxc/templates/"+template["template"]+"/provision.sh"], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)

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
            try:
                c.network[i].ipv4_address = v
            except:
                #c.append_config_item("lxc.network."+str(i)+".ipv4", v)
                c.append_config_item("lxc.network."+str(i)+".ipv4.address", v)
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
    hostdisplay = os.getenv("DISPLAY")
    print("Using display " + str(displaynum) + " on " + str(hostdisplay))
    os.system("xhost local:")
    c.attach(lxc.attach_run_command, ["/bin/su", "-l", "-c",
                                        "killall Xnest ; \
                                        Xnest -sss -name \"Xnest " +c.name+ "\" -display " + hostdisplay +" :"+str(displaynum)+" & \
                                        export DISPLAY=:"+str(displaynum)+" ; \
                                        while ! `setxkbmap fr` ; do sleep 1 ; done ; \
                                        xfce4-session &  \
                                        sleep 1 && setxkbmap fr",
                                        "debian"], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)

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
    # parser = argparse.ArgumentParser(description='Launches mini-internet')
    # parser.add_argument('-c', type=str, help='config file')
    # args = parser.parse_args()
    #
    # if args.c != None:
    #     config = args.c

    json_data = open(config).read()
    data = json.loads(json_data)
    getGlobals(data)
    getContainers(data)
    getBridges(data)
    getNics(data)
    getMITemplates(data)

#    print(containers)
#    print(bridges)
#    print(nics)
#    print(mitemplates)



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
        lxc.Container(prefixc+sys.argv[2]).attach_wait(lxc.attach_run_shell, env_policy=lxc.LXC_ATTACH_CLEAR_ENV)
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
