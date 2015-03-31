#
# Copyright (c) 2005-2006
#      The President and Fellows of Harvard College.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the University nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# Author: Geoffrey Mainland <mainland@eecs.harvard.edu>
#
# Author: Doug Carlson <carlson@cs.jhu.edu>
#  - Assign constants from Serial.py
#  - Add sequence number
#  - Handle acknowledgements correctly

from threading import Lock, Condition, Thread
from IO import IODone
from SerialH import Serial

SYNC_BYTE = Serial.HDLC_FLAG_BYTE
ESCAPE_BYTE = Serial.HDLC_CTLESC_BYTE 
MTU = 256

P_ACK = Serial.SERIAL_PROTO_ACK
P_PACKET_ACK = Serial.SERIAL_PROTO_PACKET_ACK 
P_PACKET_NO_ACK = Serial.SERIAL_PROTO_PACKET_NOACK
P_UNKNOWN = Serial.SERIAL_PROTO_PACKET_UNKNOWN

DEBUG = False
TX_ATTEMPT_LIMIT = 1


class NoAckException(Exception):
    pass

def hex(x):
    return "0x%02X" % (ord(x))


class RXThread(Thread):
    def __init__(self, prot):
        Thread.__init__(self)
        self.prot = prot

    def run(self):
        while True:
            try:
                frame = self.prot.readFramedPacket()       
                frameType = ord(frame[0])
                pdataOffset = 1
                if frameType == P_PACKET_ACK:
                    # send an ACK
                    self.prot.writeFramedPacket(P_ACK, frame[1], "", 0)
                    pdataOffset = 2
                packet = frame[pdataOffset:]
                
                if frameType == P_ACK:
                    with self.prot.ackCV:
                        if self.prot.lastAck:
                            if DEBUG:
                                print "Warning: last ack not cleared"
                        self.prot.lastAck = packet
                        self.prot.ackCV.notify()
                else:
                    with self.prot.dataCV:
                        self.prot.lastData = packet
                        self.prot.dataCV.notify()
            #OK, kind of ugly. finishing the SerialSource (ThreadTask)
            # leads (ultimately) to an IODone exception coming up
            # through here. At this point, the thread should complete.
            except Exception, e:
                with self.prot.ackCV:
                    self.prot.lastAck = None
                    self.prot.ackCV.notify()
                with self.prot.dataCV:
                    self.prot.read_exception = e # storing exception to inform the other thread
                    self.prot.lastData = None
                    self.prot.dataCV.notify()
                break


class SerialProtocol:
    def __init__(self, ins, outs):
        self.ins = ins
        self.outs = outs

        self.inSync = False
        self.seqNo = 0

        self.receiveBuffer = chr(0) * MTU

        self.received = [None] * 256
        self.received[P_ACK] = []
        self.received[P_PACKET_NO_ACK] = []
        rxLock = Lock()
        self.dataCV = Condition(rxLock)
        self.ackCV = Condition(rxLock)
        self.lastData = None
        self.lastAck = None
        self.read_exception = None
    
    #also a little ugly: can't start this thread until the
    # serial.Serial object has been opened. This should all be
    # encapsulated in a single constructor.
    def open(self):
        self.rxThread = RXThread(self)
        self.rxThread.start()
        
    def readPacket(self):
        with self.dataCV:
            self.read_exception = None
            self.dataCV.wait()
            if self.read_exception != None:
                raise self.read_exception # an exception from the other thread
            return self.lastData

    def readFramedPacket(self):
        count = 0
        escaped = False
        receiveBuffer = ""

        while True:
            if not self.inSync:
                if DEBUG:
                    print "resynchronizing...",

                while self.ins.read(1) != chr(SYNC_BYTE):
                    self.outs.write(chr(SYNC_BYTE))
                    self.outs.write(chr(SYNC_BYTE))
                if DEBUG:
                    print "synchronized"

                self.inSync = True
                count = 0
                escaped = False

                continue

            if count >= MTU:
                if DEBUG:
                    print "packet too long"
                self.inSync = False
                continue

            b = ord(self.ins.read(1))

            if escaped:
                if b == SYNC_BYTE:
                    # sync byte following escape is an error, resync
                    if DEBUG:
                        print "unexpected sync byte"
                    self.inSync = False
                    continue

                b ^= 0x20
                escaped = False;
            elif b == ESCAPE_BYTE:
                escaped = True;
                continue
            elif b == SYNC_BYTE:
                if count < 4:
                    # too-small frames are ignored
                    count = 0
                    continue

                packet = receiveBuffer[0:count - 2]
                readCrc = ord(receiveBuffer[count - 2]) \
                       | (ord(receiveBuffer[count - 1]) << 8);
                computedCrc = crc(packet)

                if DEBUG:
                    print " len: %d" % (len(receiveBuffer))
                    print " rcrc: %x ccrc: %x" % (readCrc, computedCrc)

                if readCrc == computedCrc:
                    return packet
                else:
                    if DEBUG:
                        print "bad packet"
                        print receiveBuffer
                    # We don't lose sync here. If we did, garbage on the line at
                    # startup will cause loss of the first packet.
                    count = 0
                    receiveBuffer = ""
                    continue

            receiveBuffer += chr(b)
            count += 1



    def writePacket(self, data):
        if DEBUG:
            print "Writing packet:"
            print " ".join(map(hex, data))
        attemptsLeft = TX_ATTEMPT_LIMIT
        self.seqNo = (self.seqNo + 1) %256
        while attemptsLeft:
            attemptsLeft -= 1
            try:
                self.writeFramedPacket(P_PACKET_ACK, self.seqNo, data)
                break
            except NoAckException:
                if DEBUG:
                    print "NO ACK:", self.seqNo

    def writeFramedPacket(self, frameType, sn, data):
        crc = 0
        frame = ""

        frame += chr(SYNC_BYTE)

        crc = crcByte(crc, frameType)
        frame += self.escape(chr(frameType))

        crc = crcByte(crc, sn)
        frame += self.escape(chr(sn))

        for c in data:
            crc = crcByte(crc, ord(c))
            frame += self.escape(c)

        frame += self.escape(chr(crc & 0xff))
        frame += self.escape(chr(crc >> 8))

        frame += chr(SYNC_BYTE)
        if DEBUG:
            print "Framed Write: (%x) "%sn+" ".join(map(hex, frame))
        self.outs.write(frame)
        with self.ackCV:
            self.ackCV.wait(0.25)
            if not self.lastAck or ord(self.lastAck[0]) != sn:
                raise NoAckException("No serial ACK received")
            self.lastAck = None


    def escape(self, c):
        b = ord(c)

        if b == SYNC_BYTE or b == ESCAPE_BYTE:
            return chr(ESCAPE_BYTE) + chr(b ^ 0x20)
        else:
            return c

def crc(data):
    crc = 0

    for b in data:
        crc = crcByte(crc, ord(b))

    return crc

def crcByte(crc, b):
    crc = crc ^ b << 8;

    for i in range(0, 8):
        if (crc & 0x8000) == 0x8000:
            crc = crc << 1 ^ 0x1021
        else:
          crc = crc << 1

    return crc & 0xffff;

