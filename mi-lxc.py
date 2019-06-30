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

def getGlobals(data):
    global lxcbr, prefixc, prefixbr
    lxcbr = data["nat-bridge"]
    prefixc = data["prefix-containers"]
    prefixbr = data["prefix-bridges"]
    return


def getContainers(data):
    global containers, masterc
    masterc = prefixc + "master"
    for container in data["containers"]:
        containers.append(prefixc + container["container"])
    return


def getBridges(data):
    global bridges
    for container in data["containers"]:
        for interface in container["interfaces"]:
            if interface["bridge"] != "nat-bridge":
                bridges.add(prefixbr + interface["bridge"])
    return


def getNics(data):
    global nics
    for container in data["containers"]:
        cname = prefixc + container["container"]
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
    for container in data["containers"]:
        cname = prefixc + container["container"]
        # templates = []
        if "templates" in container.keys():
            # for template in container["templates"]:
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


def createMaster():
    print("Creating master")
    c = lxc.Container(masterc)
    if c.defined:
        print("Master container already exists", file=sys.stdout)
        return c

    # can add flags=LXC_CREATE_QUIET to reduce verbosity
    if not c.create(template="download", args= {"dist": "debian",
                                                       "release": "stretch",
                                                       "arch": "amd64",
                                                       "no-validate": "true"}):
        print("Failed to create the container rootfs", file=sys.stderr)
        sys.exit(1)
    configure(c)
    provision(c)
    return c

def updateMaster():
    print("Updating master")
    c = lxc.Container(masterc)
    if c.defined:
        print("Master container exists, updating...", file=sys.stdout)
        filesdir = os.path.dirname(os.path.realpath(__file__)) + "/files/master/update.sh"
        if not os.path.isfile(filesdir):
            print("\033[31mNo update script for master !\033[0m", file=sys.stderr)
            c.stop()
            exit(1)

        c.start()
        if not c.get_ips(timeout=60):
            print("Container seems to have failed to start (no IP)", file=sys.stderr)
            sys.exit(1)

        ret = c.attach_wait(lxc.attach_run_command, ["env"] + ["MILXCGUARD=TRUE"] + [
                        "bash", "/mnt/lxc/master/update.sh"], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)
        if ret != 0:
            print("\033[31mUpdating of master failed (" + str(ret) + "), exiting...\033[0m", file=sys.stderr)
            c.stop()
            exit(1)

        c.stop()
        print("Master container updated !", file=sys.stdout)
    return c


def clone(container, mastercontainer):
    print("Cloning " + container + " from " + mastercontainer.name)
    newclone = mastercontainer.clone(container, flags=lxc.LXC_CLONE_SNAPSHOT)
    return newclone


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
        "lxc.mount.entry", filesdir.replace(" ", "\\040") + "/files mnt/lxc none ro,bind,create=dir 0 0")
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


def provision(c):
    # c = lxc.Container(master)
    folder = c.name[len(prefixc):]
    c.start()
    if not c.get_ips(timeout=60):
        print("Container seems to have failed to start (no IP)")
        sys.exit(1)

    # if c.name in mitemplates.keys():
    #     for template in mitemplates[c.name]:
    #         if (template["order"] == "before"):
    #             args = []
    #             for arg in template:
    #                 args.append(arg+"="+template[arg])
    # c.attach_wait(lxc.attach_run_command, ["env"]+args+["bash",
    # "/mnt/lxc/templates/"+template["template"]+"/provision.sh"],
    # env_policy=lxc.LXC_ATTACH_CLEAR_ENV)

    # time.sleep(2)
    #filesdir = os.path.dirname(os.path.realpath(__file__)).replace(" ", "\\040") + "/files/" + folder + "/provision.sh"
    filesdir = os.path.dirname(os.path.realpath(__file__)) + "/files/" + folder + "/provision.sh"
    if os.path.isfile(filesdir):
        ret = c.attach_wait(lxc.attach_run_command, ["env"] + ["MILXCGUARD=TRUE"] + [
                        "bash", "/mnt/lxc/" + folder + "/provision.sh"], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)
        if ret != 0:
            print("\033[31mProvisioning of " + folder + " failed (" + str(ret) + "), exiting...\033[0m")
            c.stop()
            c.destroy()
            exit(1)
    else:
#        ret = c.attach_wait(lxc.attach_run_command, ["env"] + ["http_proxy=http://"+proxy] +[
#                        "bash", "/mnt/lxc/" + folder + "/provision.sh"], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)
    #if ret > 255:
        print("No Provisioning script for " + folder)


    if c.name in mitemplates.keys():
        for template in mitemplates[c.name]:
            # if (template["order"] == "after"):
            args = ["MILXCGUARD=TRUE"]
            for arg in template:
                args.append(arg + "=" + template[arg])
            ret = c.attach_wait(lxc.attach_run_command, ["env"] + args + [
                                "bash", "/mnt/lxc/templates/" + template["template"] + "/provision.sh"], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)
            if ret != 0: # and ret != 127:
                print("\033[31mProvisioning of " + folder + "/" + template["template"] + " failed (" + str(ret) + "), exiting...\033[0m")
                c.stop()
                c.destroy()
                exit(1)

    c.stop()


def configNet(c):
    c.clear_config_item("lxc.network")
    cnics = nics[c.name]['interfaces']
    print("Configuring NICs of " + c.name + " to " + str(cnics))
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
                if ipaddress.ip_address(nics[c.name]['gateway']) in ipaddress.ip_network(v,strict=False):
                    c.network[i].ipv4_gateway = nics[c.name]['gateway']
            except ValueError:  #gateway is not a valid address, no gateway to set
                pass
        # c.network[i].script_up = "upscript"
        c.network[i].flags = "up"
        i += 1
    c.save_config()


#


def createInfra():
    mastercontainer = createMaster()
    for container in containers:
        c = lxc.Container(container)
        if c.defined:
            print("Container " + container + " already exists", file=sys.stderr)
        else:
            flushArp()
            newclone = clone(container, mastercontainer)
            provision(newclone)
            configNet(newclone)


def destroyInfra():
    for container in containers:
        destroy(container)
#    destroy(masterc)

def increaseInotify():
    print("Increasing inotify kernel parameters through sysctl")
    os.system("sysctl fs.inotify.max_queued_events=1048576 fs.inotify.max_user_instances=1048576 fs.inotify.max_user_watches=1048576 1>/dev/null")


def startInfra():
    createBridges()
    increaseInotify()
    for container in containers:
        print("Starting " + container)
        c = lxc.Container(container)
        if c.defined:
            c.start()
        else:
            print("Container " + container + " does not exist ! You need to run \"./mi-lxc.py create\"", file=sys.stderr)
            exit(1)


def stopInfra():
    for container in containers:
        print("Stopping " + container)
        c = lxc.Container(container)
        c.stop()
    deleteBridges()


def display(c, user):
    # c.attach(lxc.attach_run_command, ["Xnest", "-sss", "-name", "Xnest",
    # "-display", ":0", ":1"])
    displaynum = containers.index(c.name) + 2
    hostdisplay = os.getenv("DISPLAY")
    print("Using display " + str(displaynum) +
          " on " + str(hostdisplay) + " with user " + user)
    os.system("xhost local:")
    c.attach(lxc.attach_run_command, ["/bin/su", "-l", "-c",
                                      "killall Xnest  2>/dev/null; \
                                        Xnest -name \"Xnest " + c.name + "\" -display " + hostdisplay + " :" + str(displaynum) + " 2>/dev/null & \
                                        export DISPLAY=:" + str(displaynum) + " ; \
                                        while ! `setxkbmap fr 2>/dev/null` ; do sleep 1 ; done ; \
                                        xfce4-session 2>/dev/null &  \
                                        sleep 1 && setxkbmap fr 2>/dev/null",
                                      user], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)

#


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

    for c in containers:
        G2.add_node("c"+c, color='red', shape='box', label=c[len(prefixc):])

    for bridge in bridges:
        G2.add_node("b"+bridge, color='green', label=bridge[len(prefixbr):])

    for container in containers:
        global nics
        for nic in nics[container]['interfaces']:
            # if nic[0] == lxcbr:
            #     nicname = lxcbr
            # else:
            #     nicname = nic[0]

#            G2.add_edge(container[len(prefixc):],nicname)
            G2.add_edge("c"+container,"b"+nic[0], label = nic[1])  # with IPs

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
    for container in containers:
        str += container[len(prefixc):] + ', '
    return str

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

    if os.geteuid() != 0:
        exit("You need to have root privileges to run this script.\nExiting.")

    command = sys.argv[1]
    flushArp()

    if (command == "create"):
        createInfra()
    elif (command == "destroy"):
        if len(sys.argv) > 2:
            container = sys.argv[2]
            if (prefixc + container) in containers:
                destroy(prefixc + container)
            else:
                print("Unexisting container " + container + ", valid containers are " + listContainers(), file=sys.stderr)
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

        if (prefixc + container) in containers:
            lxccontainer = lxc.Container(prefixc + container)
            if lxccontainer.running:
                lxccontainer.attach_wait(lxc.attach_run_command, run_command, env_policy=lxc.LXC_ATTACH_CLEAR_ENV)
            else:
                print("Container " + container + " is not running. You need to run \"./mi-lxc.py start\" before attaching to a container", file=sys.stderr)
                exit(1)
        else:
            print("Unexisting container " + container + ", valid containers are " + listContainers(), file=sys.stderr)
            exit(1)
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

        if (prefixc + container) in containers:
            lxccontainer = lxc.Container(prefixc + container)
            if lxccontainer.running:
                display(lxccontainer, user)
            else:
                print("Container " + container + " is not running. You need to run \"./mi-lxc.py start\" before attaching to a container", file=sys.stderr)
                exit(1)
        else:
            print("Unexisting container " + container + ", valid containers are " + listContainers(), file=sys.stderr)
            exit(1)
    elif (command == "updatemaster"):
        updateMaster()
    elif (command == "destroymaster"):
        destroy(masterc)
    elif (command == "print"):
        printgraph()
    else:
        usage()
