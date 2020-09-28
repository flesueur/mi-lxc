#!/usr/bin/python3

#import lxc
import sys
import os
import subprocess
import json
import re
import ipaddress
import pprint
from backends import LxcBackend, DynamipsBackend

def flushArp():
    os.system("ip neigh flush dev " + lxcbr)

# def getxkbmap():
#     cmd = "setxkbmap -query | grep layout | cut -d':' -f2 | sed \"s/ //g\""
#     result = subprocess.check_output(cmd, shell=True)
#     return result.decode("utf-8")
#     #return(os.system("setxkbmap -query | grep layout | cut -d':' -f2 | sed \"s/ //g\""))

def getGlobals(data):
    global lxcbr, prefixc, prefixbr
    lxcbr = data["nat-bridge"]
    prefixc = data["prefix-containers"]
    prefixbr = data["prefix-bridges"]
    return

def merge(c1, c2):
    #print("merging")
    if "master" in c2:
        c1["master"] = c2["master"]
    c1["folder"] = c2["folder"]
    c1["templates"] = c2["templates"] + c1["templates"]
    return c1

def developTopology(data):
    global topology
    containers = {}

    for gname in data["groups"]:
        group = data["groups"][gname]

        for template in group["templates"]:
            json_data = open("templates/groups/"+template["template"]+"/local.json").read()
            datatemplate = json.loads(json_data)
            tcontainers = datatemplate["containers"]

            for cname in tcontainers:
                container = tcontainers[cname]
                container["folder"]="groups/" + gname + "/" + cname
                container["group"]= gname

                try:
                    for iface in container["interfaces"]:
                        if not "$" in iface["bridge"]:
                            iface["bridge"] = gname + sep + iface["bridge"]
                except:
                    pass

                for key in container.keys():
                    if container[key][0] == "$":
                        container[key] = template[key]

                try:
                    for iface in container["interfaces"]:
                        for key in iface:
                            if iface[key][0] == "$":
                                iface[key] = template[key]
                except KeyError:
                    pass

                for targettemplate in container["templates"]:
                    if os.path.isfile(os.path.dirname(os.path.realpath(__file__)) + "/templates/groups/" + template["template"] + "/" + targettemplate["template"] + "/provision.sh"):
                        targettemplate["folder"] = "templates/groups/" + template["template"] + "/" + targettemplate["template"]
                    for key in targettemplate.keys():
                        if targettemplate[key][0] == "$":
                            #print("parameter " + targettemplate[key])
                            try:
                                targettemplate[key] = template[key]
                            except KeyError:
                                targettemplate[key] = ""
                containers[gname+sep+cname]=container

        try:
            json_data = open("groups/"+gname+"/local.json").read()
            localtopology = json.loads(json_data)
            for cname in localtopology["containers"]:
                container = localtopology["containers"][cname]
                container["folder"]="groups/" + gname + "/" + cname
                container["group"]= gname
                try:
                    for iface in container["interfaces"]:
                        iface["bridge"] = gname + sep + iface["bridge"]
                except KeyError:
                    pass
                if (gname+sep+cname) in containers:
                    containers[gname+sep+cname]=merge(containers[gname+sep+cname], container)
                else:
                    containers[gname+sep+cname]=container
        except FileNotFoundError:
            pass

    data["containers"] = containers
    topology = containers
    return data

def getContainers(data):
    global containers
    for container in data["containers"].keys():
        containers.append(container)
    containers.sort()
    return

def getMasters(data):
    global masters
    for master in data["masters"]:
        if not ("status" in master.keys() and master['status'] == "disabled"):
            masters.append(master)
    return


def getBridges(data):
    global bridges
    for container in data["containers"].values():
        for interface in container["interfaces"]:
            if interface["bridge"] != "nat-bridge":
                bridges.add(prefixbr + interface["bridge"])
    return


def getNics(data):
    global nics
    for cname, container in data["containers"].items():
        interfaces = []
        for interface in container["interfaces"]:
            iface = interface["bridge"]
            if iface == "nat-bridge":
                iface = lxcbr
            else:
                iface = prefixbr + iface

            ips = {}
            #for ipv, address in interface["address"]:
            #    ips[ipv]=address
            ips['ipv4'] = interface['ipv4']
            if 'ipv6' in interface:
                ips['ipv6'] = interface['ipv6']

            interfaces.append((iface, ips))

            if not 'gatewayv6' in container:
                container["gatewayv6"]='None'

            nics[cname] = {'gatewayv4': container["gatewayv4"],
                            'gatewayv6': container["gatewayv6"],
                            'interfaces': interfaces}
    return



def getMITemplates(data):
    global mitemplates
    for cname, container in data["containers"].items():
        if "templates" in container.keys():
            mitemplates[cname] = container["templates"]
    return



def getMIMasters(data):
    global mimasters
    for cname, container in data["containers"].items():
        if "master" in container.keys():
            mimasters[cname] = container["master"]
        #else:   # no entry in mimasters if default master
        #    mimasters[cname] = "default"
    return

def getFolders(data):
    global folders
    for cname, container in data["containers"].items():
        folders[cname] = container["folder"]
    return

def getMasters2():
    global masters2
    for master in data["masters"]:
        if not ("status" in master.keys() and master['status'] == "disabled"):
            if master['backend'] == "lxc":
                masterc = LxcBackend.LxcMaster(name=master['name'], parameters=master['parameters'], template=master['template'], family=master['family'])
                masters2.append(masterc)
            elif master['backend'] == "dynamips":
                masterc = DynamipsBackend.DynamipsMaster(name=master['name'], rom=master['rom'], family=master['family'])
                masters2.append(masterc)
            else:
                print("Backend " + master['backend'] + " not supported, exiting", file=sys.stderr)
                exit(1)
    return

def getMaster(mastername):
    global masters2
    for master in masters2:
        if master.name == mastername:
            return master
    print("unknown master " + mastername)
    return None

def getHosts():
    global hosts
    for container in containers:
        if container in mimasters.keys():
            mastername = mimasters[container]
        else: # use default master
            mastername = masters[0]['name']
        master = getMaster(mastername)
        if master.backend == "lxc":
            newcont = LxcBackend.LxcHost(name=container, nics=nics[container], templates=mitemplates[container], master=master, folder=folders[container])
            hosts.append(newcont)
        elif master.backend == "dynamips":
            newcont = DynamipsBackend.DynamipsHost(name=container, nics=nics[container], templates=mitemplates[container], master=master, folder=folders[container])
            hosts.append(newcont)
        else:
            print("Backend " + master.backend + " not supported, exiting", file=sys.stderr)
            exit(1)

def getHost(hostname):
    global hosts
    for host in hosts:
        if host.name == hostname:
            return host
    print("unknown host " + hostname)
    return None




def getInterpreter(file):
    script = open(file)
    first = script.readline()
    interpreter = first[2:-1]
    script.close()
    return interpreter


config = "global.json"

prefixc = "lxc-infra-"
prefixbr = "lxc"
lxcbr = "lxcbr0"
sep = "-"

# Containers
containers = []
topology = {}
hosts = []

# Bridges
bridges = set()

nics = {}

mitemplates = {}

folders = {}

masters = [] # list of Masters
masters2 = []
mimasters = {} # dict of master used by containers

def createMasters():
    print("Creating masters")
    for master in masters2:
        if not master.exists():
            flushArp()
            master.create()
        else:
            print("Master container " + master.name + " already exists", file=sys.stderr)
    print("Masters created successfully !")


def updateMasters():
    print("Updating masters")
    for master in masters2:
        master.update()
    print("Masters updated successfully !")


def createInfra():
    createMasters()
    for host in hosts:
        if not host.exists():
            flushArp()
            host.create()
        else:
            print("Host " + host.name + " already exists", file=sys.stderr)
    print("Infrastructure created successfully !")

def renetInfra():
    for host in hosts:
        if not host.exists():
            print("Host " + host.name + " does not exist", file=sys.stderr)
            exit(1)
        else:
            flushArp()
            host.renet()
    print("Infrastructure reneted successfully !")


def destroyInfra():
    for host in hosts:
        host.destroy()
#    destroy(masterc)

def destroyMasters():
    for master in masters2:
        master.destroy()
#        destroy(prefixc + "masters" + sep + master['name'])


def increaseInotify():
    print("Increasing inotify kernel parameters through sysctl")
    os.system("sysctl fs.inotify.max_queued_events=1048576 fs.inotify.max_user_instances=1048576 fs.inotify.max_user_watches=1048576 1>/dev/null")


def startInfra():
    createBridges()
    increaseInotify()
    for host in hosts:
        print("Starting " + host.name)
        host.start()
# Commented out since it quite works but is too long for each container already ready. Will have to be parallelized
#    print("Waiting for containers to be ready...")
#    for host in reversed(hosts):
#        host.isReady()


def stopInfra():
    for host in hosts:
        print("Stopping " + host.name)
        host.stop()
    deleteBridges()


def createBridges():
    print("Creating bridges")
    #os.system("echo 1 > /proc/sys/net/ipv4/ip_forward")
    for bridge in bridges:
        os.system("brctl addbr " + bridge)
        os.system("ifconfig " + bridge + " up")
        os.system("iptables -A FORWARD -i " +
                  bridge + " -o " + bridge + " -j ACCEPT")



def deleteBridges():
    print("Deleting bridges")
    #os.system("echo 0 > /proc/sys/net/ipv4/ip_forward")
    for bridge in bridges:
        os.system("ifconfig " + bridge + " down")
        os.system("brctl delbr " + bridge)
        os.system("iptables -D FORWARD -i " +
                  bridge + " -o " + bridge + " -j ACCEPT")


#

def printgraph():
    import pygraphviz as pgv
    import tempfile
    from PIL import Image
    G2 = pgv.AGraph()
    G2.graph_attr['overlap'] = "false"
    G2.node_attr['style'] = "filled"

    for host in hosts:
        G2.add_node("c"+host.name, colorscheme='brbg9', color='2', shape='box', label=host.name, fontsize=10, height=0.2)

    for bridge in bridges:
        G2.add_node("b"+bridge, colorscheme='brbg9', color='4', label=bridge[len(prefixbr):], fontsize=10, height=0.1)

    G2.add_node("b"+lxcbr, colorscheme='brbg9', color='6', label=lxcbr, fontsize=10, height=0.2)
    # 69A2B0, A1C084, FFCAB1, 659157, E05263

    for host in hosts:
        for nic in host.nics['interfaces']:
            # if nic[0] == lxcbr:
            #     nicname = lxcbr
            # else:
            #     nicname = nic[0]

#            G2.add_edge(container[len(prefixc):],nicname)
            label = ""
            if 'ipv4' in nic[1]:
                label += nic[1]['ipv4']
            if 'ipv6' in nic[1]:
                label += "\n" + nic[1]['ipv6']
            G2.add_edge("c"+host.name,"b"+nic[0], label = label, fontsize = 8)  # with IPs

    #G2.write("test.dot")
    #G2.draw("test.png", prog="neato")
    fout = tempfile.NamedTemporaryFile(suffix=".png", delete=True)
    G2.draw(fout.name, prog="sfdp", format="png")
    Image.open(fout.name).show()


def usage():
    print(
        "No argument given, usage with: create, renet, destroy, destroymaster, updatemaster, start, stop, attach [user@]<name> [command], display [user@]<name>, print.\nNames are: ", end='')
    print(listHosts())

def listHosts():
    return ", ".join(host.name for host in hosts)

def terminal_size():
    import fcntl, termios, struct
    h, w, hp, wp = struct.unpack('HHHH',
        fcntl.ioctl(0, termios.TIOCGWINSZ,
        struct.pack('HHHH', 0, 0, 0, 0)))
    return w, h

def debugData(name,data):
    return
    w,h = terminal_size()
    pp = pprint.PrettyPrinter(indent=2, width=w)
    print(name + ": ")
    pp.pprint(data)
    print("\n\n")

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
    data = developTopology(data)
    debugData("Data", data)
    getContainers(data)
    debugData("Containers", containers)
    getBridges(data)
    debugData("Bridges", bridges)
    getNics(data)
    debugData("Nics", nics)
    getMITemplates(data)
    debugData("Templates", mitemplates)
    getMasters(data)
    debugData("Masters", masters)
    getMIMasters(data)
    debugData("Used masters", mimasters)
    getFolders(data)
    debugData("Folders", folders)
    getMasters2()
    debugData("Masters2", masters2)
    getHosts()
    debugData("Hosts", hosts)




    if len(sys.argv) < 2:
        usage()
        sys.exit(1)

    if os.geteuid() != 0:
        exit("You need to have root privileges to run this script.\nExiting.")

    command = sys.argv[1]
    flushArp()

    if (command == "create"):
        if len(sys.argv) > 2:
            host = getHost(sys.argv[2])
            if host is None:
                print("Unexisting container " + sys.argv[2] + ", valid containers are " + listHosts(), file=sys.stderr)
                exit(1)
            host.create()
        else:
            createInfra()
    elif (command == "destroy"):
        if len(sys.argv) > 2:
            host = getHost(sys.argv[2])
            if host is None:
                print("Unexisting container " + sys.argv[2] + ", valid containers are " + listHosts(), file=sys.stderr)
                exit(1)
            host.destroy()
        else:
            destroyInfra()
    elif (command == "start"):
        startInfra()
    elif (command == "stop"):
        stopInfra()
    elif (command == "attach"):
        if len(sys.argv) < 3:
            usage()
            sys.exit(1)
        user_container = sys.argv[2].split("@")
        if len(user_container) == 2:
            user = user_container[0]
            container = user_container[1]
        else:
            user = "root"
            container = user_container[0]

        if len(sys.argv) > 3:
            command = sys.argv[3:]
        else:
            command = None

        host = getHost(container)
        if host is None:
            print("Unexisting container " + container + ", valid containers are " + listHosts(), file=sys.stderr)
            exit(1)
        if not host.isRunning():
            print("Container " + container + " is not running. You need to run \"./mi-lxc.py start\" before attaching to a container", file=sys.stderr)
            exit(1)
        host.attach(user, command)

    elif (command == "display"):
        if len(sys.argv) < 3:
            usage()
            sys.exit(1)
        user_container = sys.argv[2].split("@")
        if len(user_container) == 2:
            user = user_container[0]
            container = user_container[1]
        else:
            user = "debian"
            container = user_container[0]

        host = getHost(container)
        if host is None:
            print("Unexisting container " + container + ", valid containers are " + listHosts(), file=sys.stderr)
            exit(1)
        if not host.isRunning():
            print("Container " + container + " is not running. You need to run \"./mi-lxc.py start\" before attaching to a container", file=sys.stderr)
            exit(1)
        host.display(user)
    elif (command == "updatemaster"):
        updateMasters()
    elif (command == "destroymaster"):
        destroyMasters()
    elif (command == "print"):
        printgraph()
    elif (command == "renet"):
        renetInfra()
    else:
        usage()
