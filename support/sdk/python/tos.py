# Copyright (c) 2008 Johns Hopkins University.
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without written
# agreement is hereby granted, provided that the above copyright
# notice, the (updated) modification history and the author appear in
# all copies of this source code.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
# OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
# THE POSSIBILITY OF SUCH DAMAGE.

# @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
# @author David Purdy <david@radioretail.co.za>

"""A library that implements the T2 serial communication.

This library has two parts: one that deals with sending and receiving
packets using the serial format from T2 (TEP113) and a second one that
tries to simplifies the work with arbitrary packets.

"""

import sys, struct, time, serial, socket, operator, thread
from Queue import Queue
from threading import Lock, Condition

__version__ = "$Id: tos.py,v 1.2 2008-07-20 22:16:50 razvanm Exp $"

__all__ = ['Serial', 'AM',
           'Packet', 'RawPacket',
           'AckFrame', 'DataFrame', 'NoAckDataFrame',
           'ActiveMessage']

ACK_WAIT = 0.2 # Maximum amount of time to wait for an ack
ACK_WARN = 0.2 # Warn if acks take longer than this to arrive

def list2hex(v):
    return " ".join(["%02x" % p for p in v])


class Error(Exception):
    """Base error class for this module"""
    pass


class TimeoutError(Error):
    """Thrown when a serial operation times out"""
    pass


class ReadError(Error):
    """Base class for read error exceptions"""
    pass


class WriteError(Error):
    """Base class for write error exceptions"""
    pass


class ReadTimeoutError(TimeoutError, ReadError):
    """Thrown when a serial read operation times out"""
    pass


class ReadCRCError(ReadError):
    """Thrown when a read packet fails a CRC check"""
    pass


class BadAckSeqnoError(ReadError):
    """Thrown if an ack packet has an unexpected sequenc number"""
    pass


class WriteTimeoutError(TimeoutError, WriteError):
    """Thrown when a serial write operation times out"""
    pass


class SimpleSerial:
    """
    A SimpleSerial object offers a way to send and data using a HDLC-like
    formating.

    Use SimpleSerial objects for basic low-level serial communications. Use
    Serial objects for higher level logic (retry sends, log printfs, etc).
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

    def __init__(self, port, baudrate, flush=False, debug=False, qsize=10,
                 timeout=None):
        self._debug = debug
        self._in_queue = []
        self._qsize = qsize
        self._ack = None
        self._write_counter = 0
        self._write_counter_failures = 0
        self._read_counter = 0
        self._ts = None
        self.timeout = timeout # Public attribute
        self._received_packet_filters = [] # filter functions for received packets

        # Remember sent (and unacknowledged) seqno numbers for 15 seconds:
        self._unacked_seqnos = SeqTracker(15.0)

        self._s = serial.Serial(port, baudrate, rtscts=0, timeout=0.5)
        self._s.flushInput()
        if flush:
            print >>sys.stdout, "Flushing the serial port",
            endtime = time.time() + 1
            while time.time() < endtime:
                try:
                    self._read()
                except ReadError:
                    pass
                sys.stdout.write(".")
            if not self._debug:
                sys.stdout.write("\n")
        self._s.close()
        self._s = serial.Serial(port, baudrate, rtscts=0, timeout=timeout)

        # Add a filter for received 'write ack' packets
        self.add_received_packet_filter(self._write_ack_filter)

    # Returns the next incoming serial packet
    def _read(self, timeout=None):
        """Wait for a packet and return it as a RawPacket.

        Throws:
         - ReadCRCError if a CRC check fails
         - ReadTimeoutError if the timeout expires.

        """

        # Developer notes:
        #
        # Packet data read from Serial is in this format:
        # [HDLC_FLAG_BYTE][Escaped data][HDLC_FLAG_BYTE]
        #
        # [Escaped data] is encoded so that [HDLC_FLAG_BYTE] byte
        # values cannot occur within it. When [Escaped data] has been
        # unescaped, the last 2 bytes are a 16-bit CRC of the earlier
        # part of the packet (excluding the initial HDLC_FLAG_BYTE
        # byte)
        #
        # It's also possible that the serial device was half-way
        # through transmitting a packet when this function was called
        # (app was just started). So we also neeed to handle this case:
        #
        # [Incomplete escaped data][HDLC_FLAG_BYTE][HDLC_FLAG_BYTE][Escaped data][HDLC_FLAG_BYTE]
        #
        # In this case we skip over the first (incomplete) packet.
        #

        if self._s.timeout != timeout and timeout != None:
            if self._debug:
                print "Set the timeout to %s, previous one was %s" % (timeout, self._s.timeout)
            self._s.timeout = timeout

        try:
            # Read bytes until we get to a HDLC_FLAG_BYTE value
            # (either the end of a packet, or the start of a new one)
            d = self._get_byte(timeout)
            ts = time.time()
            if self._debug and d != self.HDLC_FLAG_BYTE:
                print "Skipping incomplete packet"
            while d != self.HDLC_FLAG_BYTE:
                d = self._get_byte(timeout)
                ts = time.time()

            # Store HDLC_FLAG_BYTE at the start of the retrieved packet
            # data:
            packet = [d]

            # Is the next byte also HDLC_FLAG_BYTE?
            d = self._get_byte(timeout)
            if d == self.HDLC_FLAG_BYTE:
                # Yes. This means that the previous byte was for
                # the end of the previous packet, and this byte is for
                # the start of the next packet.

                # Get the 2nd byte of the new packet:
                d = self._get_byte(timeout)
                ts = time.time()

            # We are now on the 2nd byte of the packet. Add it to
            # our retrieved packet data:
            packet.append(d)

            # Read bytes from serial until we read another
            # HDLC_FLAG_BYTE value (end of the current packet):
            while d != self.HDLC_FLAG_BYTE:
                d = self._get_byte(timeout)
                packet.append(d)

            # Done reading a whole packet from serial
            if self._debug:
                print "SimpleSerial:_read: unescaped", packet

            # Decode the packet, and check CRC:
            packet = self._unescape(packet)

            crc = self._crc16(0, packet[1:-3])
            packet_crc = self._decode(packet[-3:-1])

            if crc != packet_crc:
                print "Warning: wrong CRC! %x != %x %s" % (crc, packet_crc, ["%2x" % i for i in packet])
                raise ReadCRCError
            if self._debug:
                if self._ts == None:
                    self._ts = ts
                else:
                    print "Serial:_read: %.4f (%.4f) Recv:" % (ts, ts - self._ts), self._format_packet(packet[1:-3])
                self._ts = ts

            # Packet was successfully retrieved, so return it in a
            # RawPacket wrapper object (but leave out the
            # HDLC_FLAG_BYTE and CRC bytes)
            return RawPacket(ts, packet[1:-3])
        except socket.timeout:
            raise ReadTimeoutError

    def _write_ack_filter(self, packet):
        """Filter for recieved write acknowledgement packets"""
        ack = AckFrame(packet.data)
        if ack.protocol == self.SERIAL_PROTO_ACK:
            if self._debug:
                print "_filter_read: got an ack:", ack
            self._ack = ack
            packet = None # No further processing of received ack packet
        return packet

    def _filter_read(self, timeout=None):
        """Read a packet from the serial device, perform filtering, and return
        the packet if it hasn't been processed yet.

        """
        p = self._read(timeout)
        self._read_counter += 1
        if self._debug:
            print "_filter_read: got a packet(%d): %s" % (self._read_counter, p)

        # Pass the received packet through the filter functions:
        if p is not None:
            for filter_func in self._received_packet_filters:
                p = filter_func(p)
                # Stop now if the packet doesn't need further processing:
                if p is None:
                    break

        # Return the packet (if there was no timeout and it wasn't filtered)
        return p

    def _get_ack(self, timeout, expected_seqno):
        """Get the next ack packet

        Read packets from the serial device until we get the next ack (which
        then gets stored in self._ack), or the timeout expires. non-ack packets
        are buffered.

        Throws:
         - ReadTimeoutError if the timeout expires.
         - BadAckSeqnoError if an ack with a bad sequence number is received

        """
        endtime = time.time() + timeout
        while time.time() < endtime:
            # Read the a packet over serial
            self._ack = None
            remaining = endtime - time.time()
            p = self._filter_read(timeout)

            # Was the packet filtered?
            if p:
                # Got an unfiltered packet
                if len(self._in_queue) >= self._qsize:
                    print "Warning: Buffer overflow"
                    self._in_queue.pop(0)
                self._in_queue.append(p)
            else:
                # Packet was filtered. Was it an ack?
                if self._ack is not None:
                    # The packet was an ack, so remove it from our
                    # 'unacknowledged seqnos' list (or raise a BadAckSeqnoError
                    # error if it isn't in the list)
                    self._unacked_seqnos.seqno_acked(self._ack.seqno)

                    # Stop reading packets if it's the ack we are waiting for:
                    if self._ack.seqno == expected_seqno:
                        return

        # Timed out
        raise ReadTimeoutError

    def close(self):
        """Close the serial device"""
        self._s.close()

    def read(self, timeout=None):
        """Read a packet, either from the input buffer or from the serial
        device.

        Returns a RawPacket object, otherwise None if the packet was filtered
        (by eg: Serial's printf-filtering function)

        Does not retry reads if the first one fails. Use Serial.read() for
        that.

        """
        if self._in_queue:
            return self._in_queue.pop(0)
        else:
            return self._filter_read(timeout)

    def write(self, payload, seqno, timeout=0.2):
        """
        Write a packet. If the payload argument is a list, it is
        assumed to be exactly the payload. Otherwise the payload is
        assume to be a Packet and the real payload is obtain by
        calling the .payload().

        Only attempts to write once, and times out if an ack packet is not
        received within [timeout] seconds. Use Serial.write() if you want
        automatic write retries.

        seqno should be an integer between 0 and 99 which changes each time you
        send a new packet. The value should remain the same when you are
        retrying a packet write that just failed.

        Raises WriteTimeoutError if the write times out (ack packet doesn't
        arrive within [timeout] seconds).

        """
        if type(payload) != type([]):
            # Assume this will be derived from Packet
            payload = payload.payload()
        packet = DataFrame();
        packet.protocol = self.SERIAL_PROTO_PACKET_ACK
        packet.seqno = seqno
        packet.dispatch = 0
        packet.data = payload
        packet = packet.payload()
        crc = self._crc16(0, packet)
        packet.append(crc & 0xff)
        packet.append((crc >> 8) & 0xff)
        packet = [self.HDLC_FLAG_BYTE] + self._escape(packet) + [self.HDLC_FLAG_BYTE]

        # Write the packet:
        self._unacked_seqnos.seqno_sent(seqno) # Keep track of sent seqno's
        self._put_bytes(packet)
        self._write_counter += 1

        # Wait for an ack packet:
        if self._debug:
            print "Send(%d/%d): %s" % (self._write_counter, self._write_counter_failures, packet)
            print "Wait for ack %d ..." % (seqno)

        try:
            self._get_ack(timeout, seqno)
        except ReadTimeoutError:
            # Re-raise read timeouts (of ack packets) as write timeouts (of
            # the write operation)
            self._write_counter_failures += 1
            raise WriteTimeoutError

        # Received an ack packet, with the expected sequence number
        if self._debug:
            print "Wait for ack %d done. Latest ack:" % (seqno), self._ack
            print "The packet was acked."
            print "Returning from SimpleSerial.write..."

    def add_received_packet_filter(self, filter_func):
        """Register a received packet-filtering callback function

        _filter_read() calls all of the registered filter functions for each
        packet received over serial. Registered filter functions are called in
        the order they were registered.

        Filter functions are called like this: filter_func(packet)

        When a filter function recognises and handles a received packet it
        should return a None value to indicate that no further processing
        is required for the packet.

        When a filter function skips a packet (or for some reason you want
        further processing to happen on a packet you've just processed), the
        function should return the packet that was passed to it as an argument.

        """
        self._received_packet_filters.append(filter_func)

    def remove_received_packet_filter(self, filter_func):
        """Remove a filter function added with add_received_packet_filter()"""
        self._received_packet_filters.remove(filter_func)

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

    def _crc16(self, base_crc, frame_data):
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

    def _get_byte(self, timeout=None):
#        old_timeout = self._s.timeout
#        if timeout is not None:
#            self._s.timeout = timeout
        try:
            r = struct.unpack("B", self._s.read())[0]
            return r
        except struct.error:
            # Serial port read timeout
            raise socket.timeout
#        finally:
#            self._s.timeout = old_timeout

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

    def debug(self, debug):
        self._debug = debug


class SeqTracker:
    """Class for keeping track of unacknowledged packet sequence numbers.

    SeqTracker is used by SimpleSerial to keep track of sequence numbers which
    have been sent with write packets, but not yet acknowledged by received
    write ack packets.

    """
    def __init__(self, keep_for):
        """Initialise a SeqTracker object.

        args:

         - keep_for is the length of time for which unacknowledged sequence
           numbers should be remembered. After this period has elapsed, the
           sequence numbers should be forgotten. If the sequence number is
           acknowledged later, it will be treated as unkown

        """
        self._keep_for = keep_for
        self._queue = []

    def seqno_sent(self, seqno):
        """Register that a packet with the specified sequence number was just
           sent."""
        self._gc()
        self._queue.append((seqno, time.time()))

    def seqno_acked(self, seqno):
        """Register that a sequence number was just acknowledged.

        Find the oldest-known occurance of seqno in the queue and remove it. If
        not found then raise a BadAckSeqnoError to inform applications that
        the sequence number is not known.

        """
        self._gc()
        for item in self._queue:
            if item[0] == seqno:
                # Found seqno
                self._queue.remove(item)
                return
        # seqno not found!
        raise BadAckSeqnoError

    def get_seqno_sent_times(self, seqno):
        """Return the times when packets with the given sequence number were
        sent."""
        self._gc()
        return [item[1] for item in self._queue if item[0] == seqno]

    def __contains__(self, seqno):
        """Return True if the seqno was sent recently (and not acknowledged
        yet)"""
        self._gc()
        for item in self._queue:
            if item[0] == seqno:
                return True
        return False

    def _gc(self):
        """Remove old items from the queue"""
        remove_before = time.time() - self._keep_for
        for item in self._queue:
            # Time for the sequence to be removed?
            if item[1] < remove_before:
                # Sequence data is old, so remove it
                self._queue.remove(item)
            else:
                # Sequence number was added recently, so don't remove it. Also
                # stop processing the queue because all later items will be
                # newer
                break


class Serial:
    """
    Wraps a SimpleSerial object, and provides some higher-level functionality
    like retrying writes and logging printf packets.
    """
    def __init__(self, port, baudrate, flush=False, debug=False, qsize=10,
                 timeout=None):
        """Initialise a Serial object"""
        self._debug = debug
        self.timeout = timeout # Public attribute
        self._seqno = 0
        self._simple_serial = SimpleSerial(port, baudrate, flush, debug, qsize,
                                           timeout)

        # Setup automatic logging of received printf packets:
        self._printf_msg = ""
        self._simple_serial.add_received_packet_filter(self._printf_filter)

    def close(self):
        """Close the serial device"""
        self._simple_serial.close()

    def read(self, timeout=None):
        """Read a packet from the serial port.

        Retries packet reads until the timeout expires.

        Throws ReadTimeoutError if a a packet can't be read within the timeout.

        """
        if timeout is None:
            timeout = self.timeout
        endtime = None

        if timeout is not None:
            endtime = time.time() + timeout

        while endtime is None or time.time() < endtime:
            remaining = None
            if endtime is not None:
                remaining = endtime - time.time()
            try:
                p = self._simple_serial.read(remaining)
            except ReadError:
                if self._debug:
                    print "Packet read failed. Try again."
            else:
                # Was the packet filtered?
                if p is not None:
                    # Not filtered, so return it.
                    # In the current TinyOS the packets from the mote are
                    # always NoAckDataFrame
                    return NoAckDataFrame(p.data)

        # Read timeout expired
        raise ReadTimeoutError

    def write(self, payload, timeout=None):
        """Write a packet to the serial port

        Keeps retrying endlessly, unless a timeout is set. If the timeout
        expires then WriteTimeoutError is thrown.

        """
        if timeout is None:
            timeout = self.timeout

        endtime = None
        if timeout is not None:
            endtime = time.time() + timeout

        # Generate the next sequence number:
        self._seqno = (self._seqno + 1) % 100

        while endtime is None or time.time() < endtime:
            try:
                ackwait = ACK_WAIT
                if endtime is not None:
                    remaining = endtime - time.time()
                    ackwait = min(ACK_WAIT, remaining)

                before = time.time()
                self._simple_serial.write(payload, self._seqno, ackwait)
                length = time.time() - before

                if length >= ACK_WARN:
                    print "Warning: Packet write took %.3fs!" % (length)
                return True
            except Error:
                if self._debug:
                    print "The packet was not acked. Try again."

        # Write operation timed out
        raise WriteTimeoutError

    def _printf_filter(self, packet):
        """Filter for recieved printf packets"""
        ampkt = ActiveMessage(NoAckDataFrame(packet.data).data)
        if ampkt.type == 100:
            self._printf_msg += "".join([chr(i) for i in ampkt.data]).strip('\0')
            # Split printf data on newline character:
            # (last string in the split list doesn't have a newline after
            # it, so we keep it until next time)
            lines = self._printf_msg.split('\n')
            for line in lines[:-1]:
                print "PRINTF:", line
            self._printf_msg = lines[-1]
            packet = None # No further processing for the printf packet
        return packet

class SFClient:
    def __init__(self, host, port, qsize=10):
        self._in_queue = Queue(qsize)
        self._s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._s.connect((host, port))
        data = self._s.recv(2)
        if data != 'U ':
            print "Wrong handshake"
        self._s.send("U ")
        print "Connected"
        thread.start_new_thread(self.run, ())

    def run(self):
        while True:
            length = ord(self._s.recv(1))
            data = self._s.recv(length)
            data = [ord(c) for c in data][1:]
            #print "Recv %d bytes" % (length), ActiveMessage(data)
            if self._in_queue.full():
                print "Warning: Buffer overflow"
                self._in_queue.get()
            p = RawPacket()
            p.data = data
            self._in_queue.put(p, block=False)

    def read(self, timeout=0):
        return self._in_queue.get()

    def write(self, payload):
        print "SFClient: write:", payload
        if type(payload) != type([]):
            # Assume this will be derived from Packet
            payload = payload.payload()
        payload = [0] + payload
        self._s.send(chr(len(payload)))
        self._s.send(''.join([chr(c) for c in payload]))
        return True

class AM:
    def __init__(self, s):
        self._s = s

    def read(self, timeout=None):
        return ActiveMessage(self._s.read(timeout).data)

    def write(self, packet, amid, timeout=None):
        return self._s.write(ActiveMessage(packet, amid=amid), timeout=timeout)


class SimpleSerialAM(SimpleSerial):
    """A derived class of SimpleSerial so that apps can read and write using
    higher-level packet structures.

    Serves a simalar purpose to the AM class, but for SimpleSerial objects
    instead instead of Serial.

    """

    def read_am(self, timeout=None):
        """Read a RawPacket object (or None), convert it to ActiveMessage
        (or None), and return to the caller"""

        # Get a tos.Rawpacket (or None, if filtered) object
        p = self.read(timeout)
        if p is not None:
            assert isinstance(p, RawPacket)
            # Convert tos.RawPacket object into an ActiveMessage:
            p = NoAckDataFrame(p.data)
            p = ActiveMessage(p.data)

        # Return the ActiveMessage (or None) packet:
        return p

    def write_am(self, packet, amid, seqno, timeout=2.0):
        """Convert app packet format to ActiveMessage, and write the
        ActiveMessage packet to serial"""

        # Convert from app-specific packet to ActiveMessage:
        p = ActiveMessage(packet, amid=amid)

        # Write to the serial device
        self.write(p, seqno, timeout)


class Packet:
    """
    The Packet class offers a handy way to build pack and unpack
    binary data based on a given pattern.
    """

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


class RawPacket(Packet):
    def __init__(self, ts = None, data = None):
        Packet.__init__(self,
                        [('ts' ,  'int', 4),
                         ('data', 'blob', None)],
                        None)
        self.ts = ts;
        self.data = data

class AckFrame(Packet):
    def __init__(self, payload = None):
        Packet.__init__(self,
                        [('protocol', 'int', 1),
                         ('seqno',    'int', 1)],
                        payload)

class DataFrame(Packet):
    def __init__(self, payload = None):
        if payload != None and type(payload) != type([]):
            # Assume is a Packet
            payload = payload.payload()
        Packet.__init__(self,
                        [('protocol',  'int', 1),
                         ('seqno',     'int', 1),
                         ('dispatch',  'int', 1),
                         ('data',      'blob', None)],
                        payload)

class NoAckDataFrame(Packet):
    def __init__(self, payload = None):
        if payload != None and type(payload) != type([]):
            # Assume is a Packet
            payload = payload.payload()
        Packet.__init__(self,
                        [('protocol',  'int', 1),
                         ('dispatch',  'int', 1),
                         ('data',      'blob', None)],
                        payload)

class ActiveMessage(Packet):
    def __init__(self, gpacket = None, amid = 0x00, dest = 0xFFFF):
        if type(gpacket) == type([]):
            payload = gpacket
        else:
            # Assume this will be derived from Packet
            payload = None
        Packet.__init__(self,
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
            self.type = amid
            self.data = []
            if gpacket:
                self.data = gpacket.payload()
            self.length = len(self.data)

