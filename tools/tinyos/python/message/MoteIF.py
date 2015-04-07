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
# Tinyos-2: Stephen Dawson-Haggerty

import os
import re
import struct
import sys
import traceback

from tinyos.packet.SerialH import Serial
from tinyos.message.SerialPacket import SerialPacket
import tinyos.packet.PacketDispatcher
import tinyos.packet.PacketSource
import tinyos.packet.SFSource
try:
    import tinyos.packet.SerialSource
except:
    tinyos.packet.SerialSource = None

DEBUG = False

class MoteIFException(Exception):
    def __init__(self, *args):
        self.args = args

class MoteIF:
    def __init__(self):
        self.listeners = {}

    def addListener(self, listener, msgClass):
        if listener not in self.listeners:
            self.listeners[listener] = {}

        amTypes = self.listeners[listener]
        amTypes[msgClass.get_amType()] = msgClass

    def removeListener(self, listener):
        del self.listeners[listener]

    def dispatchPacket(self, source, packet):
        #try:
            #print "Packet length: ", len(packet)
            #            print "Dispatching from MoteIF"
            #             for i in packet:
            #                 print ord(i)," ",
            #             print
        try:
            # Message.py ignores base_offset, so we'll just chop off
            # the first byte (the SERIAL_AMTYPE) here.
            serial_pkt = SerialPacket(packet[1:],
                                      data_length=len(packet)-1)
        except:
            traceback.print_exc()


        try:
            data_start = serial_pkt.offset_data(0) + 1
            data_end = data_start + serial_pkt.get_header_length()
            data = packet[data_start:data_end]
            amType = serial_pkt.get_header_type()

        except Exception, x:
            print >>sys.stderr, x
            print >>sys.stderr, traceback.print_tb(sys.exc_info()[2])

        for l, amTypes in self.listeners.items():
            if amType in amTypes:
                try:
                    msgClass = amTypes[amType]
                    msg = msgClass(data=data,
                                   data_length = len(data),
                                   addr=serial_pkt.get_header_src(),
                                   gid=serial_pkt.get_header_group())
                    l.receive(source, msg)
                except Exception, x:
                    print >>sys.stderr, x
                    print >>sys.stderr, traceback.print_tb(sys.exc_info()[2])

    def sendMsg(self, dest, addr, amType, group, msg):
        try:
            payload = msg.dataGet()
            msg = SerialPacket(None)
            msg.set_header_dest(int(addr))
            msg.set_header_group(int(group))
            msg.set_header_type(int(amType))
            msg.set_header_length(len(payload))

            # from tinyos.packet.Serial
            data = chr(Serial.TOS_SERIAL_ACTIVE_MESSAGE_ID)
            data += msg.dataGet()[0:msg.offset_data(0)]
            data += payload

            dest.writePacket(data)
        except Exception, x:
            print >>sys.stderr, x
            print >>sys.stderr, traceback.print_tb(sys.exc_info()[2])

    def addSource(self, name=None):
        if name == None:
            name = os.environ.get("MOTECOM", "sf@localhost:9002")

        m = re.match(r'([^@]*)@(.*)', name)
        if m == None:
            raise MoteIFException("base source '%s'" % (name))

        (sourceType, args) = m.groups()

        if sourceType == "sf":
            source = tinyos.packet.SFSource.SFSource(self, args)
        elif sourceType == "serial" and tinyos.packet.SerialSource != None:
            source = tinyos.packet.SerialSource.SerialSource(self, args)
        else:
            raise MoteIFException("bad source")
        source.start()
        #block until the source has started up.
        source.semaphore.acquire()
        source.semaphore.release()

        return source

    def finishAll(self):
        tinyos.packet.PacketSource.finishAll()
