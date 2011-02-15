import time
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

compress_ac = True

print 'Reading boot status (one line):'
while True:
    t = surf.readline().strip()
    while t.startswith('\0'):
        t = t[1:]
    print t
    if t.startswith('#'):
        break
    if t.startswith('!'):
        (flag, value) = t[1:].split()
        value = int(value)
        print 'flag "%s" value "%d"' % (flag, value)
        if 'compress_ac' == flag:
            compress_ac = (0 != value)
        else:
            print 'Unrecognized flag %s' % (flag,)
print 'Address/control compression: %s' % (compress_ac,)

framer = ppp4py.hdlc.HDLCforPPP(compress_ac=compress_ac)
#framer.setFrameCheckSequenceHelper(ppp4py.hdlc.FrameCheckSequenceNull)
framer.setFrameCheckSequenceHelper(ppp4py.hdlc.FrameCheckSequence16)
framer.updateReceivingACCM(0)

tests = [ 'a', 'a', 'b', "a\nb", "1\x7e2", "\x7e\x7d\x7d\x72", '12345678', '', '123' ]

def ProcessResponse_Text (framer, test):
    response = ''
    while True:
        if poller.poll(None):
            c = surf.read()
            if "\n" == c:
                print response
                response = ''
                return
            else:
                response += c

def ProcessResponse (framer, tx_text):
    return ProcessResponse_Text(framer, tx_text)
    timeout = 5000
    while poller.poll(timeout):
        c = surf.read()
        print 'RX %s' % (binascii.hexlify(c),)
        framer.putBytes(c)
        pkt = framer.getPacket()
        if (pkt is not None) and (0 < len(pkt)):
            (rx_len,) = struct.unpack('B', pkt[0])
            rx_text = pkt[1:]
            if rx_len == len(tx_text):
                if rx_text == tx_text:
                    print 'PASS rx echoed %d bytes correctly' % (rx_len)
                else:
                    print 'FAIL tx %s rx %s content error' % (binascii.hexlify(tx_text), binascii.hexlify(rx_text))
            else:
                print 'FAIL tx len %d text %s, rx len %d text %s' % (len(tx_text), binascii.hexlify(tx_text), rx_len, binascii.hexlify(rx_text))
            return

for t in tests:
    framed = framer.framePacket(t)
    print '\nTest:  %s' % (binascii.hexlify(t),)
    print 'Frame: %s' % (binascii.hexlify(framed),)
    rv = surf.write(framed)
    ProcessResponse(framer, t)
