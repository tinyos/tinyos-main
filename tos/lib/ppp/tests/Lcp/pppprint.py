import sys
import ppp4py.protocol.base

class Protocol (ppp4py.protocol.base.Protocol):
    Protocol = 0x404F
    ProtocolID = 'P4'
    ProtocolName = 'PppPrintf'

    def process (cls, information):
        sys.stdout.write(cls.Decode(information))

    @classmethod
    def Decode (cls, information):
        return 'LOG: ' + information[1:]

ppp4py.protocol.Registry[Protocol.Protocol] = Protocol
