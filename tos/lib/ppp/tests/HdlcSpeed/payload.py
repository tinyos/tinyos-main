import struct

class Payload (object):
    __FORMAT = '!HHHIIIHH'
    __LENGTH = struct.calcsize(__FORMAT)
    __FIELDS = ( 'tx_id', 'rx_length', 'rx_id', 'rx_dur_us', 'tx_dur_us', 'hdlc_errs', 'uec', 'ueb')
    tx_id = 0
    rx_length = 0
    rx_id = 0
    rx_dur_us = 0
    tx_dur_us = 0
    hdlc_errors = 0
    uec = 0
    ueb = 0

    def __init__ (self, packed=None):
        for f in self.__FIELDS:
            self.__dict__.setdefault(f, 0)
        if packed is not None:
            self.setFromPacked(packed)

    def setFromPacked (self, packed):
        self.__dict__.update(zip(self.__FIELDS, struct.unpack(self.__FORMAT, packed[:self.__LENGTH])))

    def pack (self, total_length=None):
        field_values = [ self.__dict__[_f] for _f in self.__FIELDS ]
        packed = struct.pack(self.__FORMAT, *field_values)
        if total_length is not None:
            remainder = total_length - len(packed)
            if (0 < remainder):
                packed += struct.pack('%dB' % (remainder,), *[(_v & 0xff) for _v in xrange(remainder) ])
        return packed
    
    def __str__ (self):
        return ' '.join(['%s=%d' % (_f, self.__dict__[_f]) for _f in self.__FIELDS])

