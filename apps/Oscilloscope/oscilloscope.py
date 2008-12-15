#!/usr/bin/env python

import sys
import tos

AM_OSCILLOSCOPE = 0x93

class OscilloscopeMsg(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self,
                            [('version',  'int', 2),
                             ('interval', 'int', 2),
                             ('id',       'int', 2),
                             ('count',    'int', 2),
                             ('readings', 'blob', None)],
                            packet)
if '-h' in sys.argv:
    print "Usage:", sys.argv[0], "serial@/dev/ttyUSB0:57600"
    sys.exit()

am = tos.AM()

while True:
    p = am.read()
    if p and p.type == AM_OSCILLOSCOPE:
        msg = OscilloscopeMsg(p.data)
        print msg.id, msg.count, [i<<8 | j for (i,j) in zip(msg.readings[::2], msg.readings[1::2])]
        #print msg

