#!/usr/bin/env python
import Queue
import serial
import sys
import threading
import atexit
import time
import argparse
import datetime


parser = argparse.ArgumentParser(description='Listen for frames on serial.')
parser.add_argument('port', metavar='port', type=int, nargs='?')

args = parser.parse_args()

req_port = "/dev/ttyUSB"+str(args.port)
req_baud = 115200

#dev = serial.Serial(req_port,req_baud,timeout=timeout)
device = serial.Serial(req_port,req_baud)

print "listening on port "+str(req_port)+" with "+str(req_baud)+" baud"

running = True

cafebuf = 0
cafeindex = 0
cafe = ["ca","fe","ba","be"]
cafebrewed = False


PayloadLength = str()
SequenceNum = str()
FCF = str()
DestPAN = str()
SrcPAN = str()
DestAddr = str()
SrcAddr = str()
FCS = str()
Unused = str()
Payload = str()

try:
	device.flush()
	while running:
		cafebuf = device.read(1)
		if cafebuf.encode("hex") == cafe[cafeindex]:
			cafeindex += 1
			if cafeindex is 4:
				cafebrewed = True
		if cafebrewed:
			PayloadLength = device.read(1)
			SequenceNum = device.read(1)
			FCF = device.read(2)
			DestPAN = device.read(2)
			SrcPAN = device.read(2)
			DestAddr = device.read(2)
			SrcAddr = device.read(2)
			FCS = device.read(2)
			Unused = device.read(2)
			Payload = device.read(int(PayloadLength.encode("hex"),16))
			print str(datetime.datetime.now())
			print "  PayloadLength  "+PayloadLength.encode("hex")
			print "  SequenceNum  "+SequenceNum.encode("hex")
			print "  FCF  "+FCF.encode("hex")
			print "  DestPAN  "+DestPAN.encode("hex")
			print "  SrcPAN  "+SrcPAN.encode("hex")
			print "  DestAddr  "+DestAddr.encode("hex")
			print "  SrcAddr  "+SrcAddr.encode("hex")
			print "  FCS  "+FCS.encode("hex")
			print "  Unused  "+Unused.encode("hex")
			print "  Payload  "+Payload.encode("hex")
			cafebrewed = False
			cafeindex = 0
except KeyboardInterrupt:
	running = False


#try:
#	while running:
#		length = dev.read(1)
#		print len(length),"#"+length+"#"
#		if len(length)>0:
#			data = dev.read(int(length))
#			sys.stdout.write(str(datetime.datetime.now())+"   ")
#			sys.stdout.write(data.encode("hex"))
#			sys.stdout.write("\n")
#except KeyboardInterrupt:
#	running = False

#try:
#	while running:
#		data = dev.read(1)
#		print "#"+str(len(data))+"#"
#		if len(data)>0:
#			if not dirty:
#				now = datetime.datetime.now()
##				sys.stdout.write(str(now)+"   ")
#			dirty = True
#			sys.stdout.write(data.encode("hex"))
#		else:
#			if dirty:
##				sys.stdout.write("\n")
#				pass
#			dirty = False
#		sys.stdout.write("\n")
#except KeyboardInterrupt:
#	running = False

exit(1)
