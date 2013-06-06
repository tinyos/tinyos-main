#!/usr/bin/env python

import sys, time
from tinyos import tos

class Test(tos.Packet):
    def __init__(self, payload = None):
        tos.Packet.__init__(self,
                               [('source',   'int', 2),
                                ('seqno',    'int', 2),
                                ('parent',   'int', 2),
                                ('metric',   'int', 2),
                                ('data',     'int', 2),
                                ('hopcount', 'int', 1),
                                ('sendCount','int', 2),
                                ('sendSuccessCount','int', 2)],
                               payload)

class CtpData(tos.Packet):
    def __init__(self, payload = None):
        tos.Packet.__init__(self,
                               [('options',     'int', 1),
                                ('thl',         'int', 1),
                                ('etx',         'int', 2),
                                ('origin',      'int', 2),
                                ('originSeqNo', 'int', 1),
                                ('collectionId','int', 1),
                                ('data',  'blob', None)],
                               payload)

if len(sys.argv) < 2:
    print "Usage:", sys.argv[0], "serial@/dev/ttyUSB0:57600"
    sys.exit()

#s = tos.Serial(sys.argv[1], int(sys.argv[2]), debug=False)
am = tos.AM()

while True:
    p = am.read()
    if p:
        if p.type == 238:
            ts = "%.4f" % time.time()
            ctp = CtpData(p.data)
            test = Test(ctp.data)
            print ts, '\t', ctp
            print ts, '\t', test
        else:
            print p

