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

compress_ac = False
inhibit_accomp = False

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
        elif 'inhibit_accomp' == flag:
            inhibit_accomp = (0 != value)
        else:
            print 'Unrecognized flag %s' % (flag,)
print 'Address/control compression: %s' % (compress_ac,)

framer = ppp4py.hdlc.HDLCforPPP(compress_ac=(compress_ac and not inhibit_accomp))
framer.updateReceivingACCM(0)

tests = [ 'a', 'a', 'b', "a\nb", "1\x7e2", "\x7e\x7d\x7d\x72", '123456\x7d89a\x7eABC' * 50 ]

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

num_errors = 0
def ProcessResponse (framer, tx_text):
    global num_errors
    timeout = 5000
    frame = ''
    while poller.poll(timeout):
        c = surf.read()
        #print 'RX %s' % (binascii.hexlify(c),)
        framer.putBytes(c)
        frame += c
        pkt = framer.getPacket()
        if (pkt is not None) and (0 < len(pkt)):
            print 'FRAME: %s' % (binascii.hexlify(frame),)
            # The address and control frame prefix should be present
            # iff compress_ac is false or inhibit_accomp is true.
            fi = 0
            if '\x7e' == frame[fi]:
                fi += 1
            if (not compress_ac) or inhibit_accomp:
                if '\xff\x03' != frame[fi:fi+2]:
                    print 'ERROR: Missing address/control fields'
                    num_errors += 1
            else:
                if '\xff\x03' == frame[fi:fi+2]:
                    print 'ERROR: Unexpected address/control fields'
                    num_errors += 1
            (rx_len,) = struct.unpack('B', pkt[0])
            rx_text = pkt[1:]
            if rx_len == (0xff & len(tx_text)):
                if rx_text == tx_text:
                    print 'PASS rx echoed %d bytes correctly' % (len(tx_text),)
                else:
                    print 'FAIL tx %s rx %s content error' % (binascii.hexlify(tx_text), binascii.hexlify(rx_text))
                    num_errors += 1
            else:
                print 'FAIL tx len %d text %s, rx len %d text %s' % (len(tx_text), binascii.hexlify(tx_text), rx_len, binascii.hexlify(rx_text))
                num_errors += 1
            return

for t in tests:
    framed = framer.framePacket(t)
    print '\nTest:  %s' % (binascii.hexlify(t),)
    print 'Frame: %s' % (binascii.hexlify(framed),)
    rv = surf.write(framed)
    ProcessResponse(framer, t)

print 'Total errors: %d' % (num_errors,)
