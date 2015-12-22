#!/usr/bin/env python
import Queue
import serial
import sys
import threading
import atexit
import time
import argparse
import datetime

timeout = 0.1

parser = argparse.ArgumentParser(description='Listen for frames on serial.')
parser.add_argument('port', metavar='port', type=int, nargs='?')
parser.add_argument('-t', action='store_true')
parser.add_argument('-r', action='store_true')
parser.add_argument('-l', action='store_true')

args = parser.parse_args()

device_port = "/dev/ttyUSB"+str(args.port)
device_baud = 115200

if not args.t and not args.r:
	args.t = True
	args.r = True

device = serial.Serial(device_port,device_baud)

print "listening on port "+str(device_port)+" with "+str(device_baud)+" baud"
print "listening for:"
if args.t:
	print "    transmit"
if args.r:
	print "    receive"

cafebuf = 0
cafeindex = 0
cafe = ["ca","fe","ba","be"]
cafebrewed = False

location = 0
direction = 0
data = 0
length = 0
dirty = False
running = True

try:
	device.flush()
	while running:
		cafebuf = device.read(1)
		if cafebuf.encode("hex") == cafe[cafeindex]:
			cafeindex += 1
			if cafeindex is 4:
				cafebrewed = True
		if cafebrewed:
			location = device.read(1)
			direction = device.read(1)
			length = device.read(1)
			data = 0
			if args.l:
				data = device.read(64)
			else:
				data = device.read(int(length.encode("hex"),16)) ##-2
			if ((args.t and int(direction.encode("hex"),16)==1) or (args.r and int(direction.encode("hex"),16)==2)):
				print str(datetime.datetime.now())+"  "+location.encode("hex")+"  "+direction.encode("hex")+"  "+length.encode("hex")+" "+data.encode("hex")
			cafebrewed = False
			cafeindex = 0
except KeyboardInterrupt:
	running = False


exit(1)
