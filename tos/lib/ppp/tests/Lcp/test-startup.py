import surf
import sys
import binascii
import struct
import ppp4py.hdlc
import ppp4py.protocol.base

surf = surf.Device()
framer = ppp4py.hdlc.HDLCforPPP()
pppd = ppp4py.PPP(framer=framer)

import pppprint
pppprint.PppPrintProtocol(pppd)

lcp = pppd._lcp
lcp._configureRequest.clear()
for opt in lcp.options():
    if opt.isNegotiable():
        lcp._configureRequest.appendOption(opt, opt.proposedLocalValue())
cr_frame = lcp.pack(lcp._configureRequest.pack())
#info = framer.framePacket(cr_frame)
#print binascii.hexlify(info)
#print pppd.decode(info, is_framed=False)

frame = framer.framePacket(cr_frame, compress_ac=False)
print 'TX: %s' % (binascii.hexlify(frame),)
surf.write(frame)
while True:
    pkt = surf.getPacket(framer)
    (protocol, information) = pppd.decodePacket(pkt, is_framed=False)
    if isinstance(protocol, ppp4py.protocol.base.Protocol):
        print protocol.decode(information)
    else:
        print 'Protocol %04x: %s' % (protocol, binascii.hexlify(information))
        
