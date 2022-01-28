"""
LXC backend interface
"""

from .HostBackend import Host, Master
import lxc
import ipaddress
import os
import sys


def getInterpreter(file):
    script = open(file)
    first = script.readline()
    interpreter = first[2:-1]
    script.close()
    return interpreter


class LxcBackend:
    """
    This class defines a few methods common to LxcHost and LxcMaster
    """
    nextid = 0

    def provision(self, isMaster=False, isRenet=False):
        miname = self.name
        c = self.getContainer()

        if isRenet:
            scriptname = "/renet.sh"
        else:
            scriptname = "/provision.sh"

        if isMaster:
            path = "masters/" + self.name
        else:
            path = self.folder

        filesdir = os.path.dirname(os.path.realpath(sys.modules['__main__'].__file__)) + "/" + path + scriptname
        if os.path.isfile(filesdir):
            c.start()
            if not isRenet and not c.get_ips(timeout=60):
                print("Container seems to have failed to start (no IP)")
                sys.exit(1)

        # filesdir = os.path.dirname(os.path.realpath(sys.modules['__main__'].__file__)) + "/" + path + scriptname
        # if os.path.isfile(filesdir):
            ret = c.attach_wait(lxc.attach_run_command,
                                ["env"] + ["MILXCGUARD=TRUE", "HOSTLANG=" + os.getenv("LANG")]
                                + [getInterpreter(filesdir), "/mnt/lxc/" + path + scriptname],
                                env_policy=lxc.LXC_ATTACH_CLEAR_ENV)
            if ret != 0:
                print("\033[31mProvisioning of " + path + " failed (" + str(ret) + "), exiting...\033[0m")
                c.stop()
                c.destroy()
                exit(1)
        else:
            print("No Provisioning script for " + path)

        if isinstance(self, LxcMaster):
            c.stop()
            return

        family = self.family
        for template in self.templates:
            if "folder" in template.keys():
                path = template["folder"]
            else:
                path = "templates/hosts/" + family + "/" + template["template"]

            filesdir = os.path.dirname(os.path.realpath(sys.modules['__main__'].__file__)) + "/" + path + scriptname
            if os.path.isfile(filesdir):
                c.start()
                if not isRenet and not c.get_ips(timeout=60):
                    print("Container seems to have failed to start (no IP)")
                    sys.exit(1)
                args = ["MILXCGUARD=TRUE", "HOSTLANG=" + os.getenv("LANG")]
                for arg in template:
                    args.append(arg + "=" + template[arg])
                ret = c.attach_wait(lxc.attach_run_command, ["env"] + args + [getInterpreter(filesdir), "/mnt/lxc/" + path + scriptname], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)
                if ret != 0:  # and ret != 127:
                    print("\033[31mProvisioning of " + miname + "/" + template["template"] + " failed (" + str(ret) + "), exiting...\033[0m")
                    c.stop()
                    c.destroy()
                    exit(1)
            else:
                print("No Provisioning script for " + path)

        c.stop()

    def destroy(self):
        print("Destroying " + self.name)
        c = self.getContainer()
        c.stop()
        if not c.destroy():
            print("Failed to destroy the container " + self.name, file=sys.stderr)

    def exists(self):
        c = self.getContainer()
        return c.defined

    def isReady(self):
        c = self.getContainer()
        if not c.get_ips(timeout=60):
            return False
        return True


class LxcHost(LxcBackend, Host):
    """
    This class defines methods to manage LXC hosts
    """
    def __repr__(self):
        return(
            "{" + self.backend + ":" + self.prefix + self.name
            + ", master: " + self.master.name
            + ", nics: " + str(self.nics)
            + ", templates: " + str(self.templates)
            + ", folder: " + str(self.folder)
            + ", id: " + str(self.id)
            + "}")

    def __init__(self, name, nics, templates, master, folder):
        self.prefix = "mi-"
        self.name = name
        self.backend = "lxc"
        self.lxcbr = "lxcbr0"
        self.nics = nics
        self.templates = templates
        self.master = master
        self.folder = folder
        self.family = master.family
        self.id = LxcBackend.nextid
        LxcBackend.nextid += 1

    def getContainer(self):
        return lxc.Container(self.prefix + self.name)

    def create(self):
        c = self.getContainer()
        if c.defined:
            print("Container " + self.name + " already exists", file=sys.stderr)
            return

        mastercontainer = self.master.getContainer()
        if mastercontainer.defined:
            print("Cloning " + self.name + " from " + mastercontainer.name)
            mastercontainer.clone(self.prefix + self.name, flags=lxc.LXC_CLONE_SNAPSHOT)
            self.provision()
            self.configNet()
        else:
            print("Invalid master container \"" + self.master.name + "\" for container \"" + self.name + "\"", file=sys.stderr)
            exit(1)

    def configNet(self):
        interfaces = self.nics["interfaces"]
        gatewayv4 = self.nics["gatewayv4"]
        gatewayv6 = self.nics["gatewayv6"]
        print("Configuring NICs of " + self.name + " to " + str(interfaces) + " / gwv4: " + gatewayv4 + " / gwv6: " + gatewayv6)
        c = self.getContainer()
        c.clear_config_item("lxc.net")
        i = 0
        for cnic in interfaces:
            k = cnic[0]
            v = cnic[1]
            c.network.add("veth")
            c.network[i].link = k
            c.network[i].flags = "up"

            if 'ipv4' in v:
                ipv4 = v['ipv4']
                if not (ipv4 == 'dhcp'):
                    try:
                        c.network[i].ipv4_address = ipv4
                    except:
                        # c.append_config_item("lxc.network."+str(i)+".ipv4", v)
                        c.append_config_item(
                            "lxc.net." + str(i) + ".ipv4.address", ipv4)
                    try:
                        if ipaddress.ip_address(gatewayv4) in ipaddress.ip_network(ipv4, strict=False):
                            c.network[i].ipv4_gateway = gatewayv4
                    except ValueError:  # gateway is not a valid address, no gateway to set
                        pass

            if 'ipv6' in v:
                ipv6 = v['ipv6']
                if not (ipv6 == 'dhcp'):
                    # compress IPv6 since Lxc does not accept 2001:db8::0:1
                    (ippart, netmask) = ipv6.split('/')
                    ippart = ipaddress.ip_address(ippart)
                    ipv6 = str(ippart) + '/' + netmask
                    try:
                        c.network[i].ipv6_address = ipv6
                    except:
                        # c.append_config_item("lxc.network."+str(i)+".ipv4", v)
                        c.append_config_item(
                            "lxc.net." + str(i) + ".ipv6.address", ipv6)
                    try:
                        if ipaddress.ip_address(gatewayv6) in ipaddress.ip_network(ipv6, strict=False):
                            c.network[i].ipv6_gateway = str(ipaddress.ip_address(gatewayv6))  # recompress ipv6
                    except ValueError:  # gateway is not a valid address, no gateway to set
                        pass

            i += 1

        c.save_config()

    def renet(self):
        c = self.getContainer()

        # clear network config
        c.clear_config_item("lxc.net")
        # c.network.remove(0)

        # add nated bridge
        c.network.add("veth")
        c.network[0].link = self.lxcbr
        c.network[0].flags = "up"
        c.save_config()

        # execs renet.sh
        self.provision(isRenet=True)

        # clear network config
        c.clear_config_item("lxc.net")

        # restores json network config
        self.configNet()

    def isRunning(self):
        c = self.getContainer()
        return c.running

    def start(self):
        c = self.getContainer()
        if c.defined:
            c.start()
        else:
            print("Container " + self.name + " does not exist ! You need to run \"./mi-lxc.py create\"", file=sys.stderr)
            exit(1)

    def stop(self):
        c = self.getContainer()
        if c.defined:
            c.stop()
        else:
            print("Container " + self.name + " does not exist ! You need to run \"./mi-lxc.py create\"", file=sys.stderr)
            exit(1)

    def display(self, user):
        # c.attach(lxc.attach_run_command, ["Xnest", "-sss", "-name", "Xnest",
        # "-display", ":0", ":1"])
        c = self.getContainer()
        cdisplay = ":" + str(self.id + 2)
        hostdisplay = os.getenv("DISPLAY")
        if hostdisplay is None:
            print("No $DISPLAY environment variable set, unable to diplay a container", file=sys.stderr)
            exit(1)
        os.system("xhost local: >/dev/null 2>&1")
        command = "DISPLAY=" + hostdisplay + " Xephyr -title \"Xephyr " + self.name + "\" -br -ac -dpms -s 0 -no-host-grab -resizeable " + cdisplay + " 2>/dev/null & \
            export DISPLAY=" + cdisplay + " ; \
            while ! setxkbmap -query 1>/dev/null 2>/dev/null ; do sleep 0.1s ; done ; \
            lxsession 2>/dev/null & \
            while ! pidof lxpanel 1>/dev/null ; do sleep 0.1s ; done ; \
            setxkbmap -display " + hostdisplay + " -print | xkbcomp - " + cdisplay + " 2>/dev/null"
        # xkbcomp " + str(hostdisplay) + " :" + str(displaynum)
        # setxkbmap " + getxkbmap()
        # to set a cookie in xephyr : xauth list puis ajout -cookie
        # https://unix.stackexchange.com/questions/313234/how-to-launch-xephyr-without-sleep-ing

        # print(command)
        # c.attach(lxc.attach_run_command, ["/usr/bin/pkill", "-f", "Xephyr", "-u", user], env_policy=lxc.LXC_ATTACH_CLEAR_ENV)
        c.attach(
            lxc.attach_run_command,
            ["/bin/su", "-l", "-c", command, user],
            env_policy=lxc.LXC_ATTACH_CLEAR_ENV)

    # Xnest and firefox seem incompatible with kernel.unprivileged_userns_clone=1 (need to disable the multiprocess)
    # Xephyr : can try -host-cursor

    def attach(self, user, run_command):
        if run_command is not None:
            command = " ".join(run_command)
            run_command = ["env", "TERM=" + os.getenv(
                "TERM"), "/bin/su", "-c", command, "-", user]
        else:
            run_command = [
                "env", "TERM=" + os.getenv("TERM"), "/bin/su", "-", user]
        lxccontainer = self.getContainer()
        lxccontainer.attach_wait(lxc.attach_run_command, run_command, env_policy=lxc.LXC_ATTACH_CLEAR_ENV)


class LxcMaster(LxcBackend, Master):
    """
    This class defines methods to manage LXC masters
    """
    def __repr__(self):
        return("{Master " + self.backend + ":" + self.prefix + self.name + "}")

    def __init__(self, name, parameters, template, family):
        self.prefix = "mi-"
        self.name = name
        self.backend = "lxc"
        self.lxcbr = "lxcbr0"
        self.isMaster = True
        self.template = template
        self.parameters = parameters
        self.family = family
        self.id = LxcBackend.nextid
        LxcBackend.nextid += 1

    def getContainer(self):
        return lxc.Container(self.prefix + "masters-" + self.name)

    def create(self):
        print("Creating master " + self.name)
        c = self.getContainer()
        if c.defined:
            print("Master container " + self.name + " already exists", file=sys.stdout)
            return c

        # can add flags=LXC_CREATE_QUIET to reduce verbosity
        if not c.create(template=self.template, args=self.parameters):
            print("Failed to create the container rootfs", file=sys.stderr)
            sys.exit(1)
        self.configure()
        self.provision(isMaster=True)
        print("Master " + self.name + " created successfully")
        return c

    def update(self):
        print("Updating master " + self.name)
        c = self.getContainer()
        if c.defined:
            print("Master container " + self.name + " exists, updating...", file=sys.stdout)
            path = "masters/" + self.name
            filesdir = os.path.dirname(os.path.realpath(sys.modules['__main__'].__file__)) + "/" + path + "/update.sh"
            if not os.path.isfile(filesdir):
                print("\033[31mNo update script for master !\033[0m", file=sys.stderr)
                c.stop()
                exit(1)

            c.start()
            if not c.get_ips(timeout=60):
                print("Container seems to have failed to start (no IP)", file=sys.stderr)
                sys.exit(1)

            ret = c.attach_wait(
                lxc.attach_run_command,
                ["env"] + ["MILXCGUARD=TRUE"] + [getInterpreter(filesdir), "/mnt/lxc/" + path + "/update.sh"],
                env_policy=lxc.LXC_ATTACH_CLEAR_ENV)

            if ret != 0:
                print("\033[31mUpdating of master failed (" + str(ret) + "), exiting...\033[0m", file=sys.stderr)
                c.stop()
                exit(1)

            c.stop()
            print("Master " + self.name + " updated successfully")
        return c

    def configure(self):
        # c = lxc.Container(master)
        c = self.getContainer()
        c.clear_config_item("lxc.net")
        # c.network.remove(0)
        c.network.add("veth")
        c.network[0].link = self.lxcbr
        c.network[0].flags = "up"
        c.append_config_item(
            "lxc.mount.entry", "/tmp/.X11-unix tmp/.X11-unix none ro,bind,create=dir 0 0")
        filesdir = os.path.dirname(os.path.realpath(sys.modules['__main__'].__file__))
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
