"""
Containerization/Virtualization backend interface
"""


class Master:
    """
    This class defines an interface to create masters
    """
    def create(self):
        pass

    def update(self):
        pass

    def destroy(self):
        pass


class Host:
    """
    This class defines an interface to create final containers/VM
    """
    def create(self):
        pass

    def destroy(self):
        pass

    def renet(self):
        pass

    def exists(self):
        pass

    def isRunning(self):
        pass

    def start(self):
        pass

    def stop(self):
        pass

    def display(self, user):
        pass

    def attach(self, user, run_command):
        pass

    def isReady(self):
        pass
