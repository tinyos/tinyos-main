import binascii
from connection import pppd, framer, surf, poller
import struct
import sys
import select

import pppprint
pppprint.Protocol(pppd)

import ppp4py.protocol.ccp
#ccp = ppp4py.protocol.ccp.CompressionControlProtocol(pppd)
#ccp.open()

poller.register(surf.fileno(), select.POLLIN)
stripped = []
while poller.poll(0):
    stripped.append(surf.read())
print 'Stripped: %s' % (binascii.hexlify(''.join(stripped)),)

pppd.bringLinkUp()

first_time_up = True
stop = False
print "ENTERING PPP LOOP"
text = ''
timeout_sec = None
while not stop:
    if timeout_sec is None:
        timeout_sec = 1
    events = select.POLLIN
    if pppd.hasPackets():
        events |= select.POLLOUT
    poller.register(surf.fileno(), events)
    #print 'Poll timeout %s' % (timeout_sec,)
    for (_, events) in poller.poll(timeout_sec / 1000.0):
        if events & (select.POLLHUP + select.POLLERR):
            stop = True
            break
        if events & select.POLLIN:
            c = surf.read()
            if '\n' == c:
                print text
                #print binascii.hexlify(text)
                text = ''
            elif '\x7e' == c:
                #print 'DELIMITED: %s' % (binascii.hexlify(text),)
                text = ''
            else:
                text += c
            pppd.sendToFramer(c)
    timeout_sec = pppd.execute()
    for packet in pppd.getPackets():
        print 'STX: %s' % (binascii.hexlify(packet),)
        surf.write(packet)
    surf.flush()
    if pppd._lcp.ST_opened == pppd._lcp._state:
       if first_time_up:
           first_time_up = False
           print 'UP AND RUNNING'
           #ccp.open()
           # Bounce the circuit once, to verify that things are renegotiated
           #pppd._lcp._evt_open()
           #pppd._lcp.echoRequest('hi!')
           #pppd._lcp.discardRequest('hi!')
