import time
import ppp4py
import ppp4py.protocol.lcp
import ppp4py.hdlc
import sys
import serial
import select
import binascii
import struct
import pppprint

surf_dev = '/dev/ttyUSB0'
surf = serial.Serial(surf_dev, baudrate=115200, timeout=5)
poller = select.poll()
poller.register(surf.fileno())
framer=ppp4py.hdlc.HDLCforPPP()

timeout = 5000
while poller.poll(timeout):
    c = surf.read()
    #print 'RX %s' % (binascii.hexlify(c),)
    framer.putBytes(c)
    pkt = framer.getPacket()
    if (pkt is None) or (0 == len(pkt)):
        continue
    (protocol_code, information) = ppp4py.protocol.UnpackProtocolPacket(pkt)
    protocol_class = ppp4py.protocol.Registry.get(protocol_code)
    if protocol_class is not None:
        if issubclass(protocol_class, ppp4py.protocol.base.HandlerBasedProtocol):
            ( code, id, data ) = protocol_class.Unpack(information)
            ph = protocol_class.HandlerForCode(code)
            if ph is not None:
                desc = binascii.hexlify(data)
                if issubclass(ph, ppp4py.options.OptionList_mixin):
                    desc = " ".join([ protocol_class.OptionForType(_t).ToString(data=_d) for (_t, _d) in ph.UnpackOptions(data) ])
                print '%s %s %d : %s' % (protocol_class.ProtocolID, ph.Name, id, desc)
            else:
                print '%02x %d %s' % (code, id, binascii.hexlify(data))
        elif issubclass(protocol_class, pppprint.Protocol):
            print protocol_class.Decode(information)
        else:
            print '%s %s' % (protocol_class.ProtocolID, binascii.hexlify(information))

    else:
        print '%04x %s' % (protocol_code, binascii.hexlify(information))
