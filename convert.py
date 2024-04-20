import sys

def ip_port_to_hex(address, port):
    address = address.split(".")
    address = "0x" + "".join([hex(int(i))[2:].zfill(2) for i in address[::-1]])
    port = hex(int(port))[2:]
    port = port.zfill(4)
    port = port[2:] + port[:2]
    address = address + port + "0002"
    
    return address
    
if __name__ == "__main__":
    ip = sys.argv[1]
    port = sys.argv[2]
    print(ip_port_to_hex(ip, port))