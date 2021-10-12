"""
Dynamips backend interface
"""

from .HostBackend import Host, Master
import ipaddress
import os
import sys
import subprocess
import time
import tempfile


class DynamipsBackend:
    """
    This class defines a few methods common to Host and Master
    """
    nextid = 0

    def destroy(self):
        print("Destroying " + self.name)
        return

    def exists(self):
        return True


class DynamipsHost(DynamipsBackend, Host):
    """
    This class defines methods to manage Dynamips hosts
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
        self.backend = "dynamips"
        self.lxcbr = "lxcbr0"
        self.nics = nics
        self.templates = templates
        self.master = master
        self.folder = folder
        self.rom = master.rom
        self.family = master.family
        self.id = DynamipsBackend.nextid
        DynamipsBackend.nextid += 1

    def create(self):
        return

    def genConfig(self, filename):
        fout = open(filename, "w")
        fout.write("hostname " + self.name + "\n")
        interfaces = self.nics["interfaces"]
        gatewayv4 = self.nics["gatewayv4"]
        gatewayv6 = self.nics["gatewayv6"]
        i = 0
        for cnic in interfaces:
            iface = cnic[0]
            addresses = cnic[1]
            fout.write("interface Ethernet 0/" + str(i) + "\n")
            if 'ipv4' in addresses:
                (ipv4, netmask4) = addresses['ipv4'].split('/')
                netmask4 = str(ipaddress.IPv4Network('0.0.0.0/' + netmask4).netmask)  # get the netmask from the CIDR
                # if netmask4 == "16":
                #     netmask4 = "255.255.0.0"
                # elif netmask4 == "24":
                #     netmask4 = "255.255.255.0"
                # else:
                #     netmask4 = "255.255.255.255"

                fout.write(" ip address " + ipv4 + " " + netmask4 + "\n")

            if 'ipv6' in addresses:
                (ipv6, netmask6) = addresses['ipv6'].split('/')
                fout.write(" ipv6 enable\n")
                fout.write(" ipv6 address " + addresses['ipv6'] + "\n")

            i += 1

        family = self.family
        for template in self.templates:
            if "folder" in template.keys():
                path = template["folder"]
            else:
                path = "templates/hosts/" + family + "/" + template["template"]

            filesdir = os.path.dirname(os.path.realpath(sys.modules['__main__'].__file__)) + "/" + path
            if (template['template'] == "bgprouter"):
                ascfg = open(filesdir + "/bgp.cfg").read()
                asn = template['asn']
                neighbors4 = template['neighbors4'].split(';')
                neighbors6 = template['neighbors6'].split(';')

                for neighbor4 in neighbors4:  # 100.64.0.10 as 10;100.64.0.30 as 7;
                    localas = ascfg
                    (peerip, peerasn) = neighbor4.split(' as ')
                    localas = localas.replace("$asn", asn)
                    localas = localas.replace("$peerasn", peerasn)
                    localas = localas.replace("$peerip", peerip)

                    fout.write(localas)

        fout.close

    def startNet(self):
        interfaces = self.nics["interfaces"]
        gatewayv4 = self.nics["gatewayv4"]
        gatewayv6 = self.nics["gatewayv6"]
        i = 0
        ret = ""
        for cnic in interfaces:
            iface = cnic[0]
            addresses = cnic[1]

            # tapname = self.prefix + self.name + str(i)
            tapname = self.prefix + str(self.id) + "-" + str(i)
            cmdline = "ip tuntap add mode tap name " + tapname
            ret += " -s 0:" + str(i) + ":tap:" + tapname
            os.system(cmdline)
            cmdline = "ip link set "
            cmdline += tapname
            cmdline += " up"
            os.system(cmdline)
            cmdline = "brctl addif " + iface + " " + tapname
            # print(cmdline)
            os.system(cmdline)
            i += 1

        return ret

    def stopNet(self):
        interfaces = self.nics["interfaces"]
        i = 0
        for cnic in interfaces:
            iface = cnic[0]
            addresses = cnic[1]

            # tapname = self.prefix + self.name + str(i)
            tapname = self.prefix + str(self.id) + "-" + str(i)
            cmdline = "brctl delif " + iface + " " + tapname
            # print(cmdline)
            os.system(cmdline)
            cmdline = "ip tuntap del mode tap " + tapname
            # print(cmdline)
            os.system(cmdline)
            i += 1

    def renet(self):
        pass

    def isRunning(self):
        cmdline = "screen -ls "
        cmdline += self.prefix + self.name
        cmdline += " >/dev/null"
        ret = os.system(cmdline)
        return (ret == 0)

    def start(self):
        # ip tuntap add mode tap
        # fout = tempfile.NamedTemporaryFile(suffix=".png", delete=True)
        if self.isRunning():
            return
        tmpspace = tempfile.gettempdir() + "/tmpmilxc"
        if not os.path.isdir(tmpspace):
            os.mkdir(tmpspace)
        tmpdir = tempfile.mkdtemp(prefix=self.name, dir=tmpspace)
        cmdline = "cd " + tmpdir + " && screen -S "
        cmdline += self.prefix + self.name
        cmdline += " -d -m dynamips -P 3600 "
        cmdline += "\"" + self.rom + "\""
        cmdline += " -i " + self.prefix + self.name
        cmdline += " -C config.cfg"
        cmdline += " -p 0:NM-4E "  # 0:0:tap:tap0" -t npe-400 -p 1:PA-4T+
        cmdline += self.startNet()
        # print(cmdline)
        self.genConfig(tmpdir + "/config.cfg")
        os.system(cmdline)

    def stop(self):
        cmdline = "ps aux | grep -v SCREEN | grep dynamips | grep "
        cmdline += self.prefix + self.name
        cmdline += " | awk '{print $2}'"
        pid = subprocess.check_output(cmdline, shell=True).decode("UTF-8")
        # print("pid is " + str(pid))
        if pid != "":
            os.system("kill " + str(pid))
        nbpids = 2
        cmdline += " | wc -l"
        while nbpids > 1:
            time.sleep(0.1)
            nbpids = int(subprocess.check_output(cmdline, shell=True).decode("UTF-8"))
        # cmdline = "screen -X -S "
        # cmdline += self.prefix + self.name
        # cmdline += " quit"
        # os.system(cmdline)
        self.stopNet()
        # time.sleep(1)
        # self.stopNet()

    def display(self, user):
        print("Unsupported operation for Dynamips hosts")
        pass

    def attach(self, user, run_command):
        cmdline = "screen -r "
        cmdline += self.prefix + self.name
        os.system(cmdline)


class DynamipsMaster(DynamipsBackend, Master):
    """
    This class defines methods to manage Dynamips masters
    """
    def __repr__(self):
        return(
            "{Master " + self.backend + ":" + self.prefix + self.name
            + "}")

    def __init__(self, name, rom, family):
        self.prefix = "mi-"
        self.name = name
        self.family = family
        self.backend = "dynamips"
        self.lxcbr = "lxcbr0"
        self.isMaster = True
        self.rom = os.path.realpath(rom)
        self.id = DynamipsBackend.nextid
        DynamipsBackend.nextid += 1
        if not os.path.isfile(self.rom):
            print("Dynamips ROM not found: " + self.rom)
            exit(1)

    def create(self):
        print("Creating master " + self.name)
        return

    def update(self):
        print("Updating master " + self.name)
        return
