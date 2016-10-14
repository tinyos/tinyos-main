#!/usr/bin/env python

import serial
import argparse
import struct
import time

parser = argparse.ArgumentParser(description='Listen for frames on serial.')
parser.add_argument('port', metavar='port', type=str, nargs='?')
parser.add_argument('--channel', metavar='channel', type=int, nargs='?')

args = parser.parse_args()

port_arg = args.port
req_port = None
try:
    req_port = "/dev/ttyUSB" + str(int(port_arg))
except:
    req_port = port_arg

req_baud = 115200

device = serial.Serial(req_port, req_baud)

if args.channel:
    device.write(struct.pack(">4B", 0xca, 0xfe, 0xba, args.channel))

print "listening on port " + str(req_port) + " with " + str(req_baud) + " baud, channel: " + str(args.channel)

length = 0
running = True

cafebuf = 0
cafeindex = 0
cafe = ["ca","fe","ba","be"]
cafebrewed = False

initial_timestamp = time.time()
first_timereading = None

try:
	device.flush()
	while running:
		cafebuf = device.read(1)
		if cafebuf.encode("hex") == cafe[cafeindex]:
			cafeindex += 1
			if cafeindex is 4:
				cafebrewed = True
		if cafebrewed:
			(radio_timestamp,) = struct.unpack(">I", device.read(4))
			seconds = radio_timestamp / 62500.0
			if first_timereading is None:
				first_timereading = seconds
			seconds = "%0.6f" % (seconds - first_timereading + initial_timestamp)

			length = device.read(1)
			data = device.read(int(length.encode("hex"),16))
			print str(seconds) + str(" " + length.encode("hex") + " " + data.encode("hex"))
			cafebrewed = False
			cafeindex = 0
except KeyboardInterrupt:
    running = False

exit(1)
