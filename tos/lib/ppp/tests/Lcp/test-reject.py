import sys
import binascii
import struct
import surf
import ppp4py.hdlc
import ppp4py.protocol.base

surf = surf.Device()
framer = ppp4py.hdlc.HDLCforPPP()
pppd = ppp4py.PPP(framer=framer)

import pppprint
pppprint.PppPrintProtocol(pppd)

bad_protocol = 5
bad_information = 0x12345678

pkt = framer.framePacket(struct.pack('!HI', bad_protocol, bad_information))
rv = surf.write(pkt)

# Expect to receive a Protocol-Reject message

while True:
    pkt = surf.getPacket(framer)
    (protocol, information) = pppd.decodePacket(pkt, is_framed=False)
    print type(protocol)
    if isinstance(protocol, ppp4py.protocol.lcp.LinkControlProtocol):
        (handler, identifier, data) = protocol.extract(information)
        if isinstance(handler, ppp4py.protocol.lcp.ProtocolReject):
            print 'data: %s' % (binascii.hexlify(data),)
            (rej_protocol, rej_information) = handler.extract(data)
            print '%d %d %x %s' % (bad_protocol, rej_protocol, bad_information, struct.unpack('!I', rej_information)[0])
            if (bad_protocol == rej_protocol) and (bad_information == struct.unpack('!I', rej_information)[0]):
                print "Got correct rejection"
                break
        print protocol.decode(information)
    elif isinstance(protocol, ppp4py.protocol.base.Protocol):
        print protocol.decode(information)
    else:
        print 'Protocol %04x: %s' % (protocol, binascii.hexlify(information))
    
