#!/usr/bin/env python

import sys
from tinyos import tos

class Localtime(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self,
                            [('time', 'int', 4)],
                            packet)

if '-h' in sys.argv:
    print "Usage:", sys.argv[0], "serial@/dev/ttyUSB0:57600"
    sys.exit()

am = tos.AM()

while True:
    p = am.read()
    if p:
        msg = Localtime(p.data)
        print msg
