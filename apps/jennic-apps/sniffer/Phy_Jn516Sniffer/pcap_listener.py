#!/usr/bin/env python
import Queue
import serial
import sys
import threading
import atexit
import time
import argparse
import datetime
import struct

from pcap_parser import PcapFileWriter
#from pcap_file_writer import PcapFileWriter

# Author: Tim Bormann

dumper = PcapFileWriter("sniff.pcap")
header = dumper.create_pcap_header()
dumper.write_to_pcap_file(header, file_attr="w")

parser = argparse.ArgumentParser(description='Listen for frames on serial.')
parser.add_argument('port', metavar='port', type=int, nargs='?')
parser.add_argument('--channel', metavar='channel', type=int, nargs='?')

args = parser.parse_args()

req_port = "/dev/ttyUSB"+str(args.port)
req_baud = 115200

#dev = serial.Serial(req_port,req_baud,timeout=timeout)
device = serial.Serial(req_port,req_baud)

if args.channel:
    device.write(struct.pack(">4B", 0xca, 0xfe, 0xba, args.channel))

print "listening on port "+str(req_port)+" with "+str(req_baud)+" baud, channel: " + str(args.channel)

length = 0
running = True

cafebuf = 0
cafeindex = 0
cafe = ["ca","fe","ba","be"]
cafebrewed = False


try:
    device.flush()
    while running:
        cafebuf = device.read(1)
        if cafebuf.encode("hex") == cafe[cafeindex]:
            cafeindex += 1
            if cafeindex is 4:
                cafebrewed = True
        if cafebrewed:
            (seconds,) = struct.unpack(">I", device.read(4))
            (us,) = struct.unpack(">I", device.read(4))
            length = device.read(1)
            data = device.read(int(length.encode("hex"),16))
            frame = dumper.create_pcap_frame(data)
            dumper.write_to_pcap_file(frame)
            print str(seconds) + "." + str(us) + str("  " + length.encode("hex") + " " + data.encode("hex"))
            cafebrewed = False
            cafeindex = 0
except KeyboardInterrupt:
    running = False


#try:
#   while running:
#       length = dev.read(1)
#       print len(length),"#"+length+"#"
#       if len(length)>0:
#           data = dev.read(int(length))
#           sys.stdout.write(str(datetime.datetime.now())+"   ")
#           sys.stdout.write(data.encode("hex"))
#           sys.stdout.write("\n")
#except KeyboardInterrupt:
#   running = False

#try:
#   while running:
#       data = dev.read(1)
#       print "#"+str(len(data))+"#"
#       if len(data)>0:
#           if not dirty:
#               now = datetime.datetime.now()
##              sys.stdout.write(str(now)+"   ")
#           dirty = True
#           sys.stdout.write(data.encode("hex"))
#       else:
#           if dirty:
##              sys.stdout.write("\n")
#               pass
#           dirty = False
#       sys.stdout.write("\n")
#except KeyboardInterrupt:
#   running = False

exit(1)
