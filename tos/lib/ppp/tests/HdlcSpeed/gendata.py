import time
import ppp4py.hdlc
import sys
import serial
import select
import binascii
import struct
import fcntl
import os
from payload import Payload

baudrate = 115200
#baudrate = 19200
surf_dev = '/dev/ttyUSB0'
surf = serial.Serial(surf_dev, baudrate=baudrate, timeout=5)

compress_ac = True
frame_size = 16
repetitions = 10
full_duplex = 0

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

framer = ppp4py.hdlc.HDLCforPPP(compress_ac=compress_ac)
framer.updateReceivingACCM(0)
framer.updateSendingACCM(0)

tests = [ 'a', 'a', 'b', "a\nb", "1\x7e2", "\x7e\x7d\x7d\x72" ]
tests.append('123456\x7d89a\x7eABC' * 50)

poller = select.poll()
try:
    flags = fcntl.fcntl(surf.fileno(), fcntl.F_GETFL)
    flags += os.O_NONBLOCK
    #fcntl.fcntl(surf.fileno(), fcntl.F_SETFL, flags)
except IOError, e:
    print e

# Keep from out-running the cc430 by only allowing transmission to be
# this many frames ahead of reception.  Need at least one to kick off
# the session; for full duplex, add another couple to keep this end
# busy while we're receiving more.
tx_allowed = 1
if full_duplex:
    tx_allowed += 2
tx_payload = Payload()
outgoing = ''

timeout_ms = None
rx_count = 0
while True:
    if timeout_ms is None:
        timeout_ms = 10000
    events = select.POLLIN
    if (0 == len(outgoing)) and (tx_payload is not None):
        if tx_allowed and (tx_payload.tx_id < repetitions):
            tx_payload.tx_id += 1
            outgoing += framer.framePacket(tx_payload.pack(frame_size))
            tx_allowed -= 1
            #print 'Outgoing len %d after queuing %s' % (len(outgoing), tx_payload)
    if 0 < len(outgoing):
        events |= select.POLLOUT
    poller.register(surf.fileno(), events)
    for (_, events) in poller.poll(timeout_ms):
        if events & (select.POLLHUP + select.POLLERR):
            print 'Serial error'
            break;
        if events & select.POLLIN:
            framer.putBytes(surf.read())
        if events & select.POLLOUT:
            oglen = min(1, len(outgoing))
            #oglen = len(outgoing)
            rv = surf.write(outgoing[:oglen])
            outgoing = outgoing[oglen:]
    pkt = framer.getPacket()
    while pkt is not None:
        print Payload(pkt)
        rx_count += 1
        tx_allowed += 1
        pkt = framer.getPacket()
