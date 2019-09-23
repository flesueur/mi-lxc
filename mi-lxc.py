#!/usr/bin/python3

import lxc
import sys
import os
import subprocess
import json
import re
import ipaddress
import pprint

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
            interfaces.append((iface, interface["address"]))
        nics[cname] = {'gateway': container[
            "gateway"], 'interfaces': interfaces}
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




def getInterpreter(file):
    script = open(file)
    first = script.readline()
    interpreter = first[2:-1]
    script.close()
    return interpreter

def getMasterFamily(name):
    if name in mimasters.keys():
        mastername = mimasters[name]
    else: # use default master
        mastername = masters[0]['name']
    for master in masters:
        if master["name"] == mastername:
            return master["family"]
    print ("No master family found for " + name)
    exit(1)

config = "global.json"

prefixc = "lxc-infra-"
prefixbr = "lxc"
lxcbr = "lxcbr0"
sep = "-"

# Containers
containers = []
topology = {}

# Bridges
bridges = set()

nics = {}

mitemplates = {}

folders = {}

masters = [] # list of Masters
mimasters = {} # dict of master used by containers

def createMasters():
    print("Creating masters")
    for master in masters:
        createMaster(master)
    print("Masters created successfully !")


def createMaster(master):
    print("Creating master " + master['name'])
    if master['backend'] != 'lxc':
        print("Can't create a master using " + master['backend'] + " backend, only lxc backend supported currently !", file=sys.stderr)
        exit(1)
    c = lxc.Container(prefixc + "masters" + sep + master['name'])
    if c.defined:
        print("Master container " + master['name'] + " already exists", file=sys.stdout)
        return c

    # can add flags=LXC_CREATE_QUIET to reduce verbosity
    if not c.create(template=master['template'], args= master['parameters']):
        print("Failed to create the container rootfs", file=sys.stderr)
        sys.exit(1)
    configure(c)
    provision(c, isMaster=True)
    print("Master " + master['name'] + " created successfully")
    return c

def updateMasters():
    print("Updating masters")
    for master in masters:
        updateMaster(master)
    print("Masters updated successfully !")

def updateMaster(master):
    print("Updating master " + master['name'])
    c = lxc.Container(prefixc + "masters" + sep + master['name'])
    if c.defined:
        print("Master container " +master['name']+ " exists, updating...", file=sys.stdout)
        path = "masters/" + master['name']
        filesdir = os.path.dirname(os.path.realpath(__file__)) + "/" + path + "/update.sh"
        if not os.path.isfile(filesdir):
            print("\033[31mNo update script for master !\033[0m", file=sys.stderr)
            c.stop()
            exit(1)

        c.start()
        if not c.get_ips(timeout=60):
            print("Container seems to have failed to start (no IP)", file=sys.stderr)
            sys.exit(1)

        ret = c.attach_wait(lxc.attach_run_command, ["env"] + ["MILXCGUARD=TRUE"] + [
                        getInterpreter(filesdir), "/mnt/lxc/" + path + "/update.sh"], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)
        if ret != 0:
            print("\033[31mUpdating of master failed (" + str(ret) + "), exiting...\033[0m", file=sys.stderr)
            c.stop()
            exit(1)

        c.stop()
        print("Master " + master['name'] + " updated successfully")
    return c


def create(container):
    if container in mimasters.keys():
        mastername = mimasters[container]
    else: # use default master
        mastername = masters[0]['name']
    mastercontainer = lxc.Container(prefixc + "masters" + sep + mastername)
    if mastercontainer.defined:
        print("Cloning " + container + " from " + mastercontainer.name)
        newclone = mastercontainer.clone(prefixc + container, flags=lxc.LXC_CLONE_SNAPSHOT)
        return newclone
    else:
        print("Invalid master container \"" + mastername + "\" for container \"" + container + "\"", file=sys.stderr)
        exit(1)


def destroy(container):
    print("Destroying " + container)
    c = lxc.Container(container)
    c.stop()
    if not c.destroy():
        print("Failed to destroy the container " + container, file=sys.stderr)


def configure(c):
    # c = lxc.Container(master)
    c.clear_config_item("lxc.network")
    # c.network.remove(0)
    c.network.add("veth")
    c.network[0].link = lxcbr
    c.network[0].flags = "up"
    c.append_config_item(
        "lxc.mount.entry", "/tmp/.X11-unix tmp/.X11-unix none ro,bind,create=dir 0 0")
    filesdir = os.path.dirname(os.path.realpath(__file__))
    c.append_config_item(
        "lxc.mount.entry", filesdir.replace(" ", "\\040") + " mnt/lxc none ro,bind,create=dir 0 0")
    try:  # AppArmor is installed and must be configured
        c.get_config_item("lxc.apparmor.profile")
        # may be aa_profile sometimes ?
        c.append_config_item("lxc.apparmor.profile", "unconfined")
    except:  # AppArmor is not installed and must not be configured
        pass
    try:  # AppArmor is installed and must be configured
        c.get_config_item("lxc.aa_profile")   # may be aa_profile sometimes ?
        c.append_config_item("lxc.aa_profile", "unconfined")
    except:  # AppArmor is not installed and must not be configured
        pass

    c.save_config()

def clearnet(c):
    c.clear_config_item("lxc.network")
    # c.network.remove(0)
    c.network.add("veth")
    c.network[0].link = lxcbr
    c.network[0].flags = "up"

def provision(c, isMaster=False, isRenet=False):
    miname = c.name[len(prefixc):]

    if isRenet:
        scriptname="/renet.sh"
    else:
        scriptname="/provision.sh"

    if isMaster:
        path = "masters/" + miname[len("masters"+sep):]
    else:
        path = folders[miname]

    c.start()
    if not isRenet and not c.get_ips(timeout=60):
        print("Container seems to have failed to start (no IP)")
        sys.exit(1)

    filesdir = os.path.dirname(os.path.realpath(__file__)) + "/" + path + scriptname
    if os.path.isfile(filesdir):
        ret = c.attach_wait(lxc.attach_run_command, ["env"] + ["MILXCGUARD=TRUE", "HOSTLANG="+os.getenv("LANG")] + [
                        getInterpreter(filesdir), "/mnt/lxc/" + path + scriptname], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)
        if ret != 0:
            print("\033[31mProvisioning of " + path + " failed (" + str(ret) + "), exiting...\033[0m")
            c.stop()
            c.destroy()
            exit(1)
    else:
        print("No Provisioning script for " + path)

    family = getMasterFamily(miname)
    if miname in mitemplates.keys():
        for template in mitemplates[miname]:
            if "folder" in template.keys():
                path = template["folder"]
            else:
                path = "templates/hosts/" + family + "/" + template["template"]

            filesdir = os.path.dirname(os.path.realpath(__file__)) + "/" + path + scriptname
            if os.path.isfile(filesdir):
                args = ["MILXCGUARD=TRUE", "HOSTLANG="+os.getenv("LANG")]
                for arg in template:
                    args.append(arg + "=" + template[arg])
                ret = c.attach_wait(lxc.attach_run_command, ["env"] + args + [
                                    getInterpreter(filesdir), "/mnt/lxc/" + path + scriptname], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)
                if ret != 0: # and ret != 127:
                    print("\033[31mProvisioning of " + miname + "/" + template["template"] + " failed (" + str(ret) + "), exiting...\033[0m")
                    c.stop()
                    c.destroy()
                    exit(1)
            else:
                print("No Provisioning script for " + path)

    c.stop()


def configNet(c):
    c.clear_config_item("lxc.network")
    miname = c.name[len(prefixc):]
    cnics = nics[miname]['interfaces']
    print("Configuring NICs of " + miname + " to " + str(cnics))
    c.clear_config_item("lxc.network")
    i = 0
    for cnic in cnics:
        k = cnic[0]
        v = cnic[1]
        c.network.add("veth")
        c.network[i].link = k
        if not (v == 'dhcp'):
            try:
                c.network[i].ipv4_address = v
            except:
                # c.append_config_item("lxc.network."+str(i)+".ipv4", v)
                c.append_config_item(
                    "lxc.network." + str(i) + ".ipv4.address", v)
            #if (getGateway(v) == nics[c.name]['gateway']):
            #    c.network[i].ipv4_gateway = getGateway(v)
            try:
                if ipaddress.ip_address(nics[miname]['gateway']) in ipaddress.ip_network(v,strict=False):
                    c.network[i].ipv4_gateway = nics[miname]['gateway']
            except ValueError:  #gateway is not a valid address, no gateway to set
                pass
        # c.network[i].script_up = "upscript"
        c.network[i].flags = "up"
        i += 1
    c.save_config()


#


def createInfra():
    createMasters()
    for cname in containers:
        c = lxc.Container(prefixc + cname)
        if c.defined:
            print("Container " + cname + " already exists", file=sys.stderr)
        else:
            flushArp()
            newc = create(cname)
            provision(newc, )
            configNet(newc)
    print("Infrastructure created successfully !")

def renetInfra():
    for cname in containers:
        c = lxc.Container(prefixc + cname)
        if not c.defined:
            print("Container " + cname + " does not exist", file=sys.stderr)
            exit(1)
        else:
            flushArp()
            clearnet(c)
            provision(c, isRenet=True)
            c.clear_config_item("lxc.network")
            configNet(c)
    print("Infrastructure reneted successfully !")


def destroyInfra():
    for cname in containers:
        destroy(prefixc + cname)
#    destroy(masterc)

def destroyMasters():
    for master in masters:
        destroy(prefixc + "masters" + sep + master['name'])


def increaseInotify():
    print("Increasing inotify kernel parameters through sysctl")
    os.system("sysctl fs.inotify.max_queued_events=1048576 fs.inotify.max_user_instances=1048576 fs.inotify.max_user_watches=1048576 1>/dev/null")


def startInfra():
    createBridges()
    increaseInotify()
    for cname in containers:
        print("Starting " + cname)
        c = lxc.Container(prefixc + cname)
        if c.defined:
            c.start()
        else:
            print("Container " + cname + " does not exist ! You need to run \"./mi-lxc.py create\"", file=sys.stderr)
            exit(1)


def stopInfra():
    for cname in containers:
        print("Stopping " + cname)
        c = lxc.Container(prefixc + cname)
        c.stop()
    deleteBridges()


def display(c, user):
    # c.attach(lxc.attach_run_command, ["Xnest", "-sss", "-name", "Xnest",
    # "-display", ":0", ":1"])
    cdisplay = ":" + str(containers.index(c.name[len(prefixc):]) + 2)
    hostdisplay = os.getenv("DISPLAY")
    print("Using display " + cdisplay +
          " on " + hostdisplay + " with user " + user)
    os.system("xhost local:")
    command="DISPLAY=" + hostdisplay + " Xephyr -title \"Xephyr " + c.name + "\" -br -ac -dpms -s 0 -resizeable " + cdisplay + " 2>/dev/null & \
        export DISPLAY=" + cdisplay + " ; \
        while ! `setxkbmap -query 1>/dev/null 2>/dev/null` ; do sleep 1 ; done ; \
        xfce4-session 2>/dev/null & \
        setxkbmap -display " + hostdisplay + " -print | xkbcomp - " + cdisplay + " 2>/dev/null"
        #xkbcomp " + str(hostdisplay) + " :" + str(displaynum)
        #setxkbmap " + getxkbmap()
        # to set a cookie in xephyr : xauth list puis ajout -cookie
    #print(command)
    #c.attach(lxc.attach_run_command, ["/usr/bin/pkill", "-f", "Xephyr", "-u", user], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)
    c.attach(lxc.attach_run_command, ["/bin/su", "-l", "-c",
                                        command,
                                      user], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)

# Xnest and firefox seem incompatible with kernel.unprivileged_userns_clone=1 (need to disable the multiprocess)
# Xephyr : can try -host-cursor


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

    for cname in containers:
        G2.add_node("c"+cname, color='red', shape='box', label=cname)

    for bridge in bridges:
        G2.add_node("b"+bridge, color='green', label=bridge[len(prefixbr):])

    for cname in containers:
        global nics
        for nic in nics[cname]['interfaces']:
            # if nic[0] == lxcbr:
            #     nicname = lxcbr
            # else:
            #     nicname = nic[0]

#            G2.add_edge(container[len(prefixc):],nicname)
            G2.add_edge("c"+cname,"b"+nic[0], label = nic[1])  # with IPs

    #G2.write("test.dot")
    #G2.draw("test.png", prog="neato")
    fout = tempfile.NamedTemporaryFile(suffix=".png", delete=True)
    G2.draw(fout.name, prog="sfdp", format="png")
    Image.open(fout.name).show()


def usage():
    print(
        "No argument given, usage with create, renet, destroy, destroymaster, updatemaster, start, stop, attach [user@]<name> [command], display [user@]<name>, print.\nNames are ", end='')
    print(listContainers())

def listContainers():
    str = ""
    for c in containers:
            str += c + ', '
    return str

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


    if len(sys.argv) < 2:
        usage()
        sys.exit(1)

    if os.geteuid() != 0:
        exit("You need to have root privileges to run this script.\nExiting.")

    command = sys.argv[1]
    flushArp()

    if (command == "create"):
        createInfra()
    elif (command == "destroy"):
        if len(sys.argv) > 2:
            container = sys.argv[2]
            #if (prefixc + container) in containers:
            destroy(prefixc + container)
            #else:
            #    print("Unexisting container " + container + ", valid containers are " + listContainers(), file=sys.stderr)
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
            command = " ".join(sys.argv[3:])
            run_command = ["env", "TERM=" + os.getenv(
                "TERM"), "/bin/su", "-c", command, "-", user]
        else:
            run_command = [
                "env", "TERM=" + os.getenv("TERM"), "/bin/su", "-", user]

        lxccontainer = lxc.Container(prefixc + container)
        if not lxccontainer.defined:
            print("Unexisting container " + container + ", valid containers are " + listContainers(), file=sys.stderr)
            exit(1)
        if not lxccontainer.running:
            print("Container " + container + " is not running. You need to run \"./mi-lxc.py start\" before attaching to a container", file=sys.stderr)
            exit(1)
        lxccontainer.attach_wait(lxc.attach_run_command, run_command, env_policy=lxc.LXC_ATTACH_CLEAR_ENV)

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

        lxccontainer = lxc.Container(prefixc + container)
        if not lxccontainer.defined:
            print("Unexisting container " + container + ", valid containers are " + listContainers(), file=sys.stderr)
            exit(1)
        if not lxccontainer.running:
            print("Container " + container + " is not running. You need to run \"./mi-lxc.py start\" before attaching to a container", file=sys.stderr)
            exit(1)
        display(lxccontainer, user)
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
