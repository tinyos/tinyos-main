#!/usr/bin/python

import sys
import tos_noprintfhook as tos
import os
import datetime

if '-h' in sys.argv:
	print "Usage:", sys.argv[0], "serial@/dev/ttyUSB0:115200"
	print "      ", sys.argv[0], "network@host:port"
	sys.exit()

am = tos.AM()


while True:
	packet = am.read()
	if packet:
		replacement = '\n' + str(datetime.datetime.now()) + ': '
		sys.stdout.write("".join([chr(i) for i in packet.data]).strip('\0').replace("\n", replacement))


