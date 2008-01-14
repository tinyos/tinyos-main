"""A library that implements the T2 serial communication.

This library has two parts: one that deals with sending and receiving
packets using the serial format from T2 (TEP113) and a second one that
tries to simplifies the work with arbitrary packets.

"""

import sys, struct, time, serial, socket, operator
from Queue import Queue

__version__ = "$Id: tinyos.py,v 1.4 2008-01-14 04:22:01 razvanm Exp $"

__all__ = ['Serial', 'GenericPacket', 'RawPacket',
           'AckFrame', 'DataFrame', 'NoAckDataFrame',
           'ActiveMessage']

_seqno = 1

def list2hex(v):
    return " ".join(["%02x" % p for p in v])

class Serial:
    """
    A Serial object offers a way to send and data using a HDLC-like
    formating.
    """
    
    HDLC_FLAG_BYTE = 0x7e
    HDLC_CTLESC_BYTE = 0x7d
    
    TOS_SERIAL_ACTIVE_MESSAGE_ID = 0
    TOS_SERIAL_CC1000_ID = 1
    TOS_SERIAL_802_15_4_ID = 2
    TOS_SERIAL_UNKNOWN_ID = 255
    
    SERIAL_PROTO_ACK = 67
    SERIAL_PROTO_PACKET_ACK = 68
    SERIAL_PROTO_PACKET_NOACK = 69
    SERIAL_PROTO_PACKET_UNKNOWN = 255
  
    _debug = False   # Debug mode
    
    def __init__(self, port, baudrate, flush=True):
       self._s = serial.Serial(port, baudrate, rtscts=0, timeout=0.5)
       self._queue = Queue()
       self._ts = None
       self._seqno = 0

       self._s.flushInput()
       start = time.time();
       if flush:
           print "Flushing the serial port",
           while time.time() - start < 1:
               p = self.sniff()
               sys.stdout.write(".")
           if not self._debug:
               sys.stdout.write("\n")

    def _format_packet(self, payload):
        f = NoAckDataFrame(payload)
        if f.protocol == self.SERIAL_PROTO_ACK:
            rpacket = AckFrame(payload)
            return "Ack seqno: %d" % (rpacket.seqno)
        else:
            rpacket = ActiveMessage(f.data)
            return "D: %04x S: %04x L: %02x G: %02x T: %02x | %s" % \
                   (rpacket.destination, rpacket.source,
                    rpacket.length, rpacket.group, rpacket.type,
                    list2hex(rpacket.data))

    def crc16(self, base_crc, frame_data):
        crc = base_crc
        for b in frame_data:
            crc = crc ^ (b << 8)
            for i in range(0, 8):
                if crc & 0x8000 == 0x8000:
                    crc = (crc << 1) ^ 0x1021
                else:
                    crc = crc << 1
                crc = crc & 0xffff
        return crc
    
    def _encode(self, val, dim):
        output = []
        for i in range(dim):
            output.append(val & 0xFF)
            val = val >> 8
        return output
    
    def _decode(self, v):
        r = long(0)
        for i in v[::-1]:
            r = (r << 8) + i
        return r
    
    def _get_byte(self):
        try:
            r = struct.unpack("B", self._s.read())[0]
            return r
        except struct.error:
            # Serial port read timeout
            raise socket.timeout
    
    def _put_bytes(self, data):
        #print "DEBUG: _put_bytes:", data
        for b in data:
            self._s.write(struct.pack('B', b))
    
    def _unescape(self, packet):
        r = []
        esc = False
        for b in packet:
            if esc:
                r.append(b ^ 0x20)
                esc = False
            elif b == self.HDLC_CTLESC_BYTE:
                esc = True
            else:
                r.append(b)
        return r
    
    def _escape(self, packet):
        r = []
        for b in packet:
            if b == self.HDLC_FLAG_BYTE or b == self.HDLC_CTLESC_BYTE:
                r.append(self.HDLC_CTLESC_BYTE)
                r.append(b ^ 0x20)
            else:
                r.append(b)
        return r
    
    # Returns the next incoming serial packet
    def sniff(self, skip_queue = False):
        """Wait for a packet and return it as a RawPacket."""
        
        if (not skip_queue and not self._queue.empty()):
            print "DEBUG: sniff_packet: return a packet from the queue(%d)." % self._queue.qsize()
            return self._queue.get()
        try:
            d = self._get_byte()
            ts = time.time()
            while d != self.HDLC_FLAG_BYTE:
                d = self._get_byte()
                ts = time.time()
            packet = [d]
            d = self._get_byte()
            if d == self.HDLC_FLAG_BYTE:
                d = self._get_byte()
                ts = time.time()
            else:
                packet.append(d)
            while d != self.HDLC_FLAG_BYTE:
                d = self._get_byte()
                packet.append(d)
            if self._debug == True:
                print "sniff: unescaped", packet
            packet = self._unescape(packet)
            
            crc = self.crc16(0, packet[1:-3])
            packet_crc = self._decode(packet[-3:-1])
            
            if self._debug:
                if crc != packet_crc:
                    print "Warning: wrong CRC! %s" % packet
                if self._ts == None:
                    self._ts = ts
                else:
                    print "%.4f (%.4f) Recv:" % (ts, ts - self._ts), self._format_packet(packet[1:-3])
                self._ts = ts
            return RawPacket(ts, packet[1:-3], crc == packet_crc)
        except socket.timeout:
            return None

    def sniff_am(self, skip_queue = False, timeout=0):
        """Wait for a packet and return it as a ActiveMessage."""
        
        start = time.time();
        p = None
        done = False
        while not done:
            while p == None:
                if timeout == 0 or time.time() - start < timeout:
                    p = self.sniff(skip_queue)
                else:
                    return None
            if p.crc:
                done = True
        return ActiveMessage(NoAckDataFrame(p.data).data)

    
    # Sends data with the specified AM group ID and AM ID. To have a "reliable"
    # transfer, num_tries defines how many times to retry before giving up
    def write(self, payload, num_tries=3):
        """
        Write a packet. If the payload argument is a list, it is
        assumed to be exactly the payload. Otherwise the payload is
        assume to be a GenericPacket and the real payload is obtain
        by calling the .payload().
        """
        
        global _seqno
        if type(payload) != type([]):
            # Assume this will be derived from GenericPacket
            payload = payload.payload()
        _seqno = (_seqno + 1) % 100
        packet = DataFrame();
        packet.protocol = self.SERIAL_PROTO_PACKET_ACK
        packet.seqno = _seqno
        packet.dispatch = 0
        packet.data = payload
        packet = packet.payload()
        crc = self.crc16(0, packet)
        packet.append(crc & 0xff)
        packet.append((crc >> 8) & 0xff)
        packet = [self.HDLC_FLAG_BYTE] + self._escape(packet) + [self.HDLC_FLAG_BYTE]

        for i in range(num_tries):
            self._put_bytes(packet)
            if self._debug == True:
                print "Send:", packet
            
            # Waits for ACK
            for j in range(3):
                p = self.sniff(skip_queue = True)
                if p != None:
                    ack = AckFrame(p.data)
                    if ack.protocol == self.SERIAL_PROTO_ACK:
                        if ack.seqno != _seqno:
                            print ">" * 40, "Wrong ACK!", ack.seqno, _seqno, "<" * 40
                        return True
                    else:
                        if self._debug == True:
                            print "write_packet: put a packet in the queue(%d)." % (self._queue.qsize())
                        self._queue.put(p)
                        
        return False
    
    def debug(self, debug):
        self._debug = debug



class GenericPacket:
    """ GenericPacket """

    def _decode(self, v):
        r = long(0)
        for i in v:
            r = (r << 8) + i
        return r
    
    def _encode(self, val, dim):
        output = []
        for i in range(dim):
            output.append(int(val & 0xFF))
            val = val >> 8
        output.reverse()
        return output
    
    def __init__(self, desc, packet = None):
        offset = 0
        boffset = 0
        sum = 0
        for i in range(len(desc)-1, -1, -1):
            (n, t, s) = desc[i]
            if s == None:
                if sum > 0:
                    desc[i] = (n, t, -sum)
                break
            sum += s
        self.__dict__['_schema'] = [(t, s) for (n, t, s) in desc]
        self.__dict__['_names'] = [n for (n, t, s) in desc]
        self.__dict__['_values'] = []
        if type(packet) == type([]):
            for (t, s) in self._schema:
                if t == 'int':
                    self._values.append(self._decode(packet[offset:offset + s]))
                    offset += s
                elif t == 'bint':
                    doffset = 8 - (boffset + s)
                    self._values.append((packet[offset] >> doffset) & ((1<<s) - 1))
                    boffset += s
                    if boffset == 8:
                        offset += 1
                        boffset = 0
                elif t == 'string':
                    self._values.append(''.join([chr(i) for i in packet[offset:offset + s]]))
                    offset += s
                elif t == 'blob':
                    if s:
                        if s > 0:
                            self._values.append(packet[offset:offset + s])
                            offset += s
                        else:
                            self._values.append(packet[offset:s])
                            offset = len(packet) + s
                    else:
                        self._values.append(packet[offset:])
        elif type(packet) == type(()):
            for i in packet:
                self._values.append(i)
        else:
            for v in self._schema:
                self._values.append(None)

    def __repr__(self):
        return self._values.__repr__()

    def __str__(self):
        r = ""
        for i in range(len(self._names)):
            r += "%s: %s " % (self._names[i], self._values[i])
        for i in range(len(self._names), len(self._values)):
            r += "%s" % self._values[i]
        return r
#        return self._values.__str__()

    # Implement the map behavior
    def __getitem__(self, key):
        return self.__getattr__(key)

    def __setitem__(self, key, value):
        self.__setattr__(key, value)

    def __len__(self):
        return len(self._values)

    def keys(self):
        return self._names

    def values(self):
        return self._names

    # Implement the struct behavior
    def __getattr__(self, name):
        #print "DEBUG: __getattr__", name
        if type(name) == type(0):
            return self._names[name]
        else:
            return self._values[self._names.index(name)]

    def __setattr__(self, name, value):
        if type(name) == type(0):
            self._values[name] = value
        else:
            self._values[self._names.index(name)] = value

    def __ne__(self, other):
        if other.__class__ == self.__class__:
            return self._values != other._values
        else:
            return True

    def __eq__(self, other):
        if other.__class__ == self.__class__:
            return self._values == other._values
        else:
            return False

    def __nonzero__(self):
        return True;

    # Custom
    def names(self):
        return self._names

    def sizes(self):
        return self._schema

    def payload(self):
        r = []
        boffset = 0
        for i in range(len(self._schema)):
            (t, s) = self._schema[i]
            if t == 'int':
                r += self._encode(self._values[i], s)
                boffset = 0
            elif t == 'bint':
                doffset = 8 - (boffset + s)
                if boffset == 0:
                    r += [self._values[i] << doffset]
                else:
                    r[-1] |= self._values[i] << doffset
                boffset += s
                if boffset == 8:
                    boffset = 0
            elif self._values[i] != []:
                r += self._values[i]
        for i in self._values[len(self._schema):]:
            r += i
        return r


class RawPacket(GenericPacket):
    def __init__(self, ts = None, data = None, crc = None):
        GenericPacket.__init__(self,
                               [('ts' , 'int', 4),
                                ('crc', 'int', 1),
                                ('data', 'blob', None)],
                               None)
        self.ts = ts;
        self.data = data
        self.crc = crc
        

class AckFrame(GenericPacket):
    def __init__(self, payload = None):
        GenericPacket.__init__(self,
                               [('protocol',  'int', 1),
                                ('seqno',  'int', 1)],
                               payload)

class DataFrame(GenericPacket):
    def __init__(self, payload = None):
        if payload != None and type(payload) != type([]):
            # Assume is a GenericPacket
            payload = payload.payload()
        GenericPacket.__init__(self,
                               [('protocol',  'int', 1),
                                ('seqno',  'int', 1),
                                ('dispatch',  'int', 1),
                                ('data', 'blob', None)],
                               payload)

class NoAckDataFrame(GenericPacket):
    def __init__(self, payload = None):
        if payload != None and type(payload) != type([]):
            # Assume is a GenericPacket
            payload = payload.payload()
        GenericPacket.__init__(self,
                               [('protocol',  'int', 1),
                                ('dispatch',  'int', 1),
                                ('data', 'blob', None)],
                               payload)

class ActiveMessage(GenericPacket):
    def __init__(self, gpacket = None, am_id = 0x00, dest = 0xFFFF):
        if type(gpacket) == type([]):
            payload = gpacket
        else:
            # Assume this will be derived from GenericPacket
            payload = None
        GenericPacket.__init__(self,
                               [('destination', 'int', 2),
                                ('source',   'int', 2),
                                ('length',   'int', 1),
                                ('group',    'int', 1),
                                ('type',     'int', 1),
                                ('data',     'blob', None)],
                               payload)
        if payload == None:
            self.destination = dest
            self.source = 0x0000
            self.group = 0x00
            self.type = am_id
            self.data = gpacket.payload()
            self.length = len(self.data)

