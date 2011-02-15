import time
import ppp4py
import ppp4py.hdlc
import sys
import serial
import select
import binascii
import struct

surf_dev = '/dev/ttyUSB0'
surf = serial.Serial(surf_dev, baudrate=115200, timeout=5)
poller = select.poll()
poller.register(surf.fileno())

compress_ac = False

def waitForSync ():
    print 'Reading boot status (one line):'
    finished_header = False
    while not finished_header:
        t = surf.readline().strip()
        while t.startswith('\0'):
            t = t[1:]
        print t
        if t.startswith('#'):
            finished_header = True
            break
        if t.startswith('!'):
            try:
                (flag, value) = t[1:].split()
                value = int(value)
                print 'flag "%s" value "%d"' % (flag, value)
                if 'compress_ac' == flag:
                    compress_ac = (0 != value)
                elif 'frame_size' == flag:
                    frame_size = value
                elif 'repetitions' == flag:
                    repetitions = value
                elif 'full_duplex' == flag:
                    full_duplex = value
                else:
                    print 'Unrecognized flag %s' % (flag,)
            except Exception, e:
                print e
    print 'Address/control compression: %s' % (compress_ac,)
    
framer=ppp4py.hdlc.HDLCforPPP(compress_ac=compress_ac)
pppd = ppp4py.PPP(framer=framer)

def GetPacket ():
    timeout = 5000
    while poller.poll(timeout):
        c = surf.read()
        #print 'RX %s' % (binascii.hexlify(c),)
        framer.putBytes(c)
        pkt = framer.getPacket()
        if (pkt is not None) and (0 < len(pkt)):
            return pkt
