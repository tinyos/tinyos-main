#!/usr/bin/python

import sys
import tos_noprintfhook as tos
import os

if '-h' in sys.argv:
	print "Usage:", sys.argv[0], "serial@/dev/ttyUSB0:115200"
	print "      ", sys.argv[0], "network@host:port"
	sys.exit()

am = tos.AM()

while True:
	packet = am.read()
	if packet:
		print packet
		print " "

