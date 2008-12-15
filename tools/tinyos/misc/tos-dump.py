#!/usr/bin/env python

import sys
import tos

if '-h' in sys.argv:
    print "Usage:", sys.argv[0], "serial@/dev/ttyUSB0:57600"
    print "      ", sys.argv[0], "network@host:port"
    sys.exit()

am = tos.AM()

while True:
    p = am.read()
    if p:
	print p

