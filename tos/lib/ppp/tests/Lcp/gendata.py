import binascii
from connection import pppd, framer, surf, poller
import struct
import sys

pkt = pppd.getPacket();
print binascii.hexlify(pkt)
rv = surf.write(pkt)
while True:
    sys.stdout.write(surf.read())
