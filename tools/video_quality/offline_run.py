"""Block Python TCP connections while running an installed research script locally."""
import runpy
import socket
import sys


def block_network():
    original_connect = socket.socket.connect
    original_connect_ex = socket.socket.connect_ex

    def connect(self, address):
        if self.family in (socket.AF_INET, socket.AF_INET6):
            raise RuntimeError("Offline inference: network connection blocked; install all weights beforehand")
        return original_connect(self, address)

    def connect_ex(self, address):
        if self.family in (socket.AF_INET, socket.AF_INET6):
            raise RuntimeError("Offline inference: network connection blocked")
        return original_connect_ex(self, address)

    socket.socket.connect = connect
    socket.socket.connect_ex = connect_ex


if __name__ == "__main__":
    block_network()
    sys.argv = sys.argv[1:]
    from pathlib import Path
    sys.path.insert(0, str(Path(sys.argv[0]).resolve().parent))
    runpy.run_path(sys.argv[0], run_name="__main__")
