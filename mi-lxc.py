#!/usr/bin/python3

import lxc
import sys
import os
import subprocess
import json
import re
import ipaddress

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


def getContainers(data):
    global containers
    for asn in data["aslist"]:
        asname = asn["as"]
        localcont = set()
        localcont.add("router")
        try:
            json_data = open("as/"+asname+"/local.json").read()
            localtopology = json.loads(json_data)
            for container in localtopology["containers"]:
                localcont.add(container["container"])
        except FileNotFoundError:
            pass
        containers[asname] = localcont
    return

def getMasters(data):
    global masters
    for master in data["masters"]:
        if not ("status" in master.keys() and master['status'] == "disabled"):
            masters.append(master)
    return


def getBridges(data):
    global bridges
    for asn in data["aslist"]:
        asname = asn["as"]
        for interface in asn["interfaces"]:
            if interface["bridge"] != "nat-bridge":
                bridges.add(prefixbr + interface["bridge"])
        try:
            json_data = open("as/"+asname+"/local.json").read()
            localtopology = json.loads(json_data)
            for container in localtopology["containers"]:
                try:
                    for interface in container["interfaces"]:
                        if interface["bridge"] != "nat-bridge":
                            bridges.add(prefixbr + asname + "-" + interface["bridge"])
                except KeyError:  # routers in local.json have no interfaces keyword
                    pass
        except FileNotFoundError:
            pass
    return


def getNics(data):
    global nics
    for asn in data["aslist"]:
        asname = asn["as"]
        cname = asname + sep + "router"
        interfaces = []
        for interface in asn["interfaces"]:
            iface = interface["bridge"]
            if iface == "nat-bridge":
                iface = lxcbr
            else:
                iface = prefixbr + iface
            interfaces.append((iface, interface["address"]))
        nics[cname] = {'gateway': None, 'interfaces': interfaces}

        try:
            json_data = open("as/"+asname+"/local.json").read()
            localtopology = json.loads(json_data)
            for container in localtopology["containers"]:
                if container["container"] == "router":   # router nics are configured in global.json
                    continue
                cname = asname + sep + container["container"]
                interfaces = []
                for interface in container["interfaces"]:
                    iface = interface["bridge"]
                    if iface == "nat-bridge":
                        iface = lxcbr
                    else:
                        iface = prefixbr + asname + "-" + iface
                    interfaces.append((iface, interface["address"]))
                nics[cname] = {'gateway': container[
                    "gateway"], 'interfaces': interfaces}
        except FileNotFoundError:
            pass

    return


def getMITemplates(data):
    global mitemplates
    for asn in data["aslist"]:
        asname = asn["as"]
        rname = asname + sep + "router"
        if "asdev" in asn:
            mitemplates[rname] = [{"template":"bgprouter", "asn":asn["asn"], "neighbors":asn["neighbors"], "asdev":asn["asdev"]}]
        else:
            mitemplates[rname] = [{"template":"bgprouter", "asn":asn["asn"], "neighbors":asn["neighbors"]}]
        try:
            json_data = open("as/"+asname+"/local.json").read()
            localtopology = json.loads(json_data)
            for container in localtopology["containers"]:
                cname = asname + sep + container["container"]
                if "templates" in container.keys():
                    if container["container"] == "router":
                        mitemplates[cname]+=(container["templates"])
                    else:
                        mitemplates[cname] = container["templates"]
        except FileNotFoundError:
            pass
        mitemplates[rname]+=[{"template":"nodhcp", "domain":"milxc", "ns":"10.10.10.10"}]
    return


def getMIMasters(data):
    global mimasters
    for asn in data["aslist"]:
        asname = asn["as"]
        rname = asname + sep + "router"
        mimasters[rname] = "alpine"
        try:
            json_data = open("as/"+asname+"/local.json").read()
            localtopology = json.loads(json_data)
            for container in localtopology["containers"]:
                cname = asname + sep + container["container"]
                if "master" in container.keys():
                    mimasters[cname] = container["master"]
        except FileNotFoundError:
            pass
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
containers = {}

# Bridges
bridges = set()

nics = {}

mitemplates = {}

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
    provision(c, "masters")
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


def provision(c, namespace):
    miname = c.name[len(prefixc) + len(namespace) + 1:]
    if namespace is "masters":
        path = namespace + "/" + miname
    else:
        path = "/as/" + namespace + "/" + miname
    c.start()
    if not c.get_ips(timeout=60):
        print("Container seems to have failed to start (no IP)")
        sys.exit(1)

    filesdir = os.path.dirname(os.path.realpath(__file__)) + "/" + path + "/provision.sh"
    if os.path.isfile(filesdir):
        ret = c.attach_wait(lxc.attach_run_command, ["env"] + ["MILXCGUARD=TRUE", "HOSTLANG="+os.getenv("LANG")] + [
                        getInterpreter(filesdir), "/mnt/lxc/" + path + "/provision.sh"], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)
        if ret != 0:
            print("\033[31mProvisioning of " + path + " failed (" + str(ret) + "), exiting...\033[0m")
            c.stop()
            c.destroy()
            exit(1)
    else:
        print("No Provisioning script for " + path)

    fname = namespace + sep + miname
    family = getMasterFamily(fname)
    if fname in mitemplates.keys():
        for template in mitemplates[fname]:
            filesdir = os.path.dirname(os.path.realpath(__file__)) + "/templates/hosts/" + family + "/" + template["template"] + "/provision.sh"
            args = ["MILXCGUARD=TRUE", "HOSTLANG="+os.getenv("LANG")]
            for arg in template:
                args.append(arg + "=" + template[arg])
            ret = c.attach_wait(lxc.attach_run_command, ["env"] + args + [
                                getInterpreter(filesdir), "/mnt/lxc/templates/hosts/" + family + "/" + template["template"] + "/provision.sh"], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)
            if ret != 0: # and ret != 127:
                print("\033[31mProvisioning of " + fname + "/" + template["template"] + " failed (" + str(ret) + "), exiting...\033[0m")
                c.stop()
                c.destroy()
                exit(1)

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
    for asn in containers.keys():
        for container in containers[asn]:
            cname = asn + sep + container
            c = lxc.Container(prefixc + cname)
            if c.defined:
                print("Container " + cname + " already exists", file=sys.stderr)
            else:
                flushArp()
                newc = create(cname)
                provision(newc, asn)
                configNet(newc)
    print("Infrastructure created successfully !")


def destroyInfra():
    for asn in containers.keys():
        for container in containers[asn]:
            destroy(prefixc + asn + sep + container)
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
    for asn in containers.keys():
        for container in containers[asn]:
            cname = asn + sep + container
            print("Starting " + cname)
            c = lxc.Container(prefixc + cname)
            if c.defined:
                c.start()
            else:
                print("Container " + cname + " does not exist ! You need to run \"./mi-lxc.py create\"", file=sys.stderr)
                exit(1)


def stopInfra():
    for asn in containers.keys():
        for container in containers[asn]:
            cname = asn + sep + container
            print("Stopping " + cname)
            c = lxc.Container(prefixc + cname)
            c.stop()
    deleteBridges()


def display(c, user):
    # c.attach(lxc.attach_run_command, ["Xnest", "-sss", "-name", "Xnest",
    # "-display", ":0", ":1"])
    cdisplay = ":" + str(getAllContainers().index(c.name[len(prefixc):]) + 2)
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

    for asn in containers:
        for c in containers[asn]:
            G2.add_node("c"+asn+c, color='red', shape='box', label=asn+sep+c)

    for bridge in bridges:
        G2.add_node("b"+bridge, color='green', label=bridge[len(prefixbr):])

    for asn in containers:
        for c in containers[asn]:
            global nics
            for nic in nics[asn+sep+c]['interfaces']:
                # if nic[0] == lxcbr:
                #     nicname = lxcbr
                # else:
                #     nicname = nic[0]

    #            G2.add_edge(container[len(prefixc):],nicname)
                G2.add_edge("c"+asn+c,"b"+nic[0], label = nic[1])  # with IPs

    #G2.write("test.dot")
    #G2.draw("test.png", prog="neato")
    fout = tempfile.NamedTemporaryFile(suffix=".png", delete=True)
    G2.draw(fout.name, prog="sfdp", format="png")
    Image.open(fout.name).show()


def usage():
    print(
        "No argument given, usage with create, destroy, destroymaster, updatemaster, start, stop, attach [user@]<name> [command], display [user@]<name>, print.\nNames are ", end='')
    print(listContainers())

def listContainers():
    str = ""
    for asn in containers:
        for c in containers[asn]:
            str += asn + sep + c + ', '
    return str

def getAllContainers():
    mycontainers = []
    for asn in containers:
        for c in containers[asn]:
            mycontainers.append(asn + sep + c)
    return sorted(mycontainers)

def debugData(name,data):
    return
    print(name + ": " + str(data) + "\n\n")

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
    else:
        usage()
