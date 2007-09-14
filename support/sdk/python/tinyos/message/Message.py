#
# Copyright (c) 2005
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
# Authors: Geoffrey Mainland <mainland@eecs.harvard.edu>
#          Philip Levis <pal@cs.stanford.edu>

import struct

class MessageException(Exception):
    def __init__(self, *args):
        self.args = args

class Message:
    def __init__(self, data, addr=None, gid=None, base_offset=0, data_length=None):
        self.addr = addr
        self.gid = gid
        self.data = data
        self.base_offset = base_offset
        if data_length != None:
            self.data_length = data_length

            if data == None or len(data) != data_length:
                self.data = chr(0) * data_length

        else:
            self.data_length = len(data)

            self.am_type = 0
            
    def dataGet(self):
        return self.data

    def baseOffset(self):
        return self.base_offset

    def dataLength(self):
        return self.data_length

    def getAddr(self):
        return self.addr

    def getGid(self):
        return self.gid

    def amType(self):
        return self.am_type

    def amTypeSet(self, type):
        self.am_type = type

    def checkBounds(self, offset, length):
        if offset < 0 or length <= 0 or offset + length > (self.data_length * 8):
            raise MessageException("Message.checkBounds: bad offset (%d) or length (%d), for data_length %d" \
                                   % (offset, length, self.data_length))

        if offset & 7 != 0:
            raise MessageException("Cannot deal with bit fields")

        if length & 7 != 0:
            raise MessageException("Cannot deal with bit fields")

    def getUIntElement(self, offset, length, endian):
        self.checkBounds(offset, length)
        
        byteOffset = offset >> 3
        bitOffset = offset & 7

        if (endian):
            endian = ">"
        else:
            endian = "<"
            
        temp = self.data[byteOffset:byteOffset + (length >> 3)]

        if length == 8:
            return struct.unpack("B", temp)[0]
        elif length == 16:
            return struct.unpack(endian + "H", temp)[0]
        elif length == 32:
            return struct.unpack(endian + "L", temp)[0]
        else:
            raise MessageException("Bad length")

    def setUIntElement(self, offset, length, val, endian):
        self.checkBounds(offset, length)

        byteOffset = offset >> 3
        bitOffset = offset & 7

        if (endian):
            endian = ">"
        else:
            endian = "<"
            
        if length == 8:
            temp = struct.pack(endian + "B", val)
        elif length == 16:
            temp = struct.pack(endian + "H", val)
        elif length == 32:
            temp = struct.pack(endian + "L", val)
        else:
            raise MessageException("Bad length")

        self.data = self.data[:byteOffset] + temp + self.data[byteOffset + (length >> 3):]

    def getSIntElement(self, offset, length, endian):
        self.checkBounds(offset, length)

        byteOffset = offset >> 3
        bitOffset = offset & 7

        if (endian):
            endian = ">"
        else:
            endian = "<"

        temp = self.data[byteOffset:byteOffset + (length >> 3)]

        if length == 8:
            return struct.unpack(endian + "b", temp)[0]
        elif length == 16:
            return struct.unpack(endian + "h", temp)[0]
        elif length == 32:
            return struct.unpack(endian + "l", temp)[0]
        else:
            raise MessageException("Bad length")

    def setSIntElement(self, offset, length, val, endian):
        self.checkBounds(offset, length)

        byteOffset = offset >> 3
        bitOffset = offset & 7

        if (endian):
            endian = ">"
        else:
            endian = "<"

        if length == 8:
            temp = struct.pack(endian + "b", val)
        elif length == 16:
            temp = struct.pack(endian + "h", val)
        elif length == 32:
            temp = struct.pack(endian + "l", val)
        else:
            raise MessageException("Bad length")

        self.data = self.data[:byteOffset] + temp + self.data[byteOffset + (length >> 3):]

    def getFloatElement(self, offset, length, endian):
        self.checkBounds(offset, length)

        byteOffset = offset >> 3
        bitOffset = offset & 7

        if (endian):
            endian = ">"
        else:
            endian = "<"

        temp = self.data[byteOffset:byteOffset + (length >> 3)]

        return struct.unpack(endian + "f", temp)[0]

    def setFloatElement(self, offset, length, value, endian):
        self.checkBounds(offset, length)

        byteOffset = offset >> 3
        bitOffset = offset & 7

        if (endian):
            endian = ">"
        else:
            endian = "<"

        temp = struct.pack(endian + "f", value)

        self.data = self.data[:byteOffset] + temp + self.data[byteOffset + (length >> 3):]
