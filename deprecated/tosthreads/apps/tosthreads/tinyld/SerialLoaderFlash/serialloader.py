#!/usr/bin/env python

# Copyright (c) 2008 Johns Hopkins University.
# All rights reserved.
#
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions
 # are met:
 #
 # - Redistributions of source code must retain the above copyright
 #   notice, this list of conditions and the following disclaimer.
 # - Redistributions in binary form must reproduce the above copyright
 #   notice, this list of conditions and the following disclaimer in the
 #   documentation and/or other materials provided with the
 #   distribution.
 # - Neither the name of the copyright holders nor the names of
 #   its contributors may be used to endorse or promote products derived
 #   from this software without specific prior written permission.
 #
 # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 # "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 # LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 # FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 # THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 # INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 # (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 # SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 # HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 # STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 # ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 # OF THE POSSIBILITY OF SUCH DAMAGE.

# @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>

import sys, os, stat, struct
import tinyos

SERIALMSG_AMGROUP = 0
SERIALMSG_AMID    = 0xAB

SERIALMSG_ERASE = 0
SERIALMSG_WRITE = 1
SERIALMSG_READ  = 2
SERIALMSG_CRC   = 3
SERIALMSG_LEDS   = 5
SERIALMSG_RUN   = 7

SERIALMSG_SUCCESS = 0
SERIALMSG_FAIL    = 1

SERIALMSG_DATA_PAYLOAD_SIZE = 20
DELUGE_VOLUME_SIZE = 262144

HEX_OUTPUT_LINE_SIZE = 16

class SerialReqPacket(tinyos.GenericPacket):
  def __init__(self, packet = None):
      tinyos.GenericPacket.__init__(self,
                             [('msg_type', 'int', 1),
                              ('pad', 'int', 1),
                              ('offset', 'int', 2),
                              ('len', 'int', 2),
                              ('data', 'blob', None)],
                             packet)

class SerialReplyPacket(tinyos.GenericPacket):
  def __init__(self, packet = None):
      tinyos.GenericPacket.__init__(self,
                             [('error', 'int', 1),
                              ('pad', 'int', 1),
                             ('data', 'blob', None)],
                             packet)

# Display an integer representation of byte stream to hex representation
def print_hex(start_addr, byte_stream):
  byte_stream = ["%02x" % one_byte for one_byte in byte_stream]   # Converts to each byte to hex
  
  num_iterations = int( (len(byte_stream) - 1) / HEX_OUTPUT_LINE_SIZE )
  num_iterations += 1
  
  for i in range(num_iterations):
    line = "%07x" % start_addr + " "   # Prints memory address
    for j in range(HEX_OUTPUT_LINE_SIZE):
      if (i * HEX_OUTPUT_LINE_SIZE + j) < len(byte_stream):
        line += byte_stream[i * HEX_OUTPUT_LINE_SIZE + j] + " "
    print line
    
    start_addr += HEX_OUTPUT_LINE_SIZE

def op_run(s, sreqpkt):
  success = s.write_packet(SERIALMSG_AMGROUP, SERIALMSG_AMID, sreqpkt.payload())
  if success == True:
    packet = s.read_packet()
    sreplypkt = SerialReplyPacket(packet[1])
    return (sreplypkt.error == SERIALMSG_SUCCESS)

def op_erase(s, sreqpkt):
  success = s.write_packet(SERIALMSG_AMGROUP, SERIALMSG_AMID, sreqpkt.payload())
  if success == True:
    packet = s.read_packet()
    sreplypkt = SerialReplyPacket(packet[1])
    return (sreplypkt.error == SERIALMSG_SUCCESS)

def op_print(s, sreqpkt, offset, length):
  if (offset + length) <= DELUGE_VOLUME_SIZE:
    while length > 0:
      sreqpkt.offset = offset
      # Calculates the payload size for the reply packet
      if length >= HEX_OUTPUT_LINE_SIZE:
        sreqpkt.len = HEX_OUTPUT_LINE_SIZE
      else:
        sreqpkt.len = length
      
      success = s.write_packet(SERIALMSG_AMGROUP, SERIALMSG_AMID, sreqpkt.payload())
      if success == True:
        packet = s.read_packet()
        sreplypkt = SerialReplyPacket(packet[1])
        if sreplypkt.error != SERIALMSG_SUCCESS:
          return False
  
      print_hex(offset, sreplypkt.data)
      length -= sreqpkt.len
      offset += sreqpkt.len
  else:
    print "ERROR: Specified offset and length are too large for the flash volume"
    return False
  
  return True

def op_write(s, sreqpkt, input_file, length):
  local_crc = 0
  input_file_size = length
  
  sreqpkt.offset = 0
  while length > 0:
    # Calculates the payload size for the current packet
    if length >= SERIALMSG_DATA_PAYLOAD_SIZE:
      sreqpkt.len = SERIALMSG_DATA_PAYLOAD_SIZE
    else:
      sreqpkt.len = length
    sreqpkt.data = []
    
    # Reads in the file we want to transmit
    for i in range(sreqpkt.len):
      sreqpkt.data.append(struct.unpack("B", input_file.read(1))[0])
    
    # Sends over serial to the mote
    if s.write_packet(SERIALMSG_AMGROUP, SERIALMSG_AMID, sreqpkt.payload()) == True:
      # Waiting for confirmation
      packet = s.read_packet()
      sreplypkt = SerialReplyPacket(packet[1])
      if sreplypkt.error != SERIALMSG_SUCCESS:
        return False
      local_crc = s.crc16(local_crc, sreqpkt.data)   # Computes running CRC
    else:
      print "ERROR: Unable to write to flash"
      return False
    
    length -= sreqpkt.len
    sreqpkt.offset += sreqpkt.len
  
  # Check local and remote CRC
  sreqpkt.msg_type = SERIALMSG_CRC
  remote_crc = op_crc(s, sreqpkt, 0, input_file_size)
  if remote_crc != None:
    local_crc = [(local_crc >> 8) & 0xFF, local_crc & 0xFF]
    print "Local CRC:  " + ("%02x" % local_crc[0]) + " " + ("%02x" % local_crc[1])
    print "Remote CRC: " + ("%02x" % remote_crc[0]) + " " + ("%02x" % remote_crc[1])
    if remote_crc != local_crc:
      print "ERROR: Remote CRC doesn't match local CRC"
      return False
  else:
    print "ERROR: Unable to verify CRC"
    return False
    
  return True

def op_crc(s, sreqpkt, offset, length):
  sreqpkt.offset = offset
  sreqpkt.len = length
  success = s.write_packet(SERIALMSG_AMGROUP, SERIALMSG_AMID, sreqpkt.payload())
  if success == True:
    packet = s.read_packet()
    sreplypkt = SerialReplyPacket(packet[1])
    if sreplypkt.error == SERIALMSG_SUCCESS:
      return sreplypkt.data
    else:
      return None

def op_leds(s, sreqpkt):
  success = s.write_packet(SERIALMSG_AMGROUP, SERIALMSG_AMID, sreqpkt.payload())

# ======== MAIN ======== #
if len(sys.argv) >= 3:
  sys.argv[2] = int(sys.argv[2])
  
  s = tinyos.Serial(sys.argv[1], 57600)
  s.set_debug(False)   # Disables debug msg
  sreqpkt = SerialReqPacket((sys.argv[2], 0, 0, 0, []))   # msg_type, pad, offset, length, data
  
  if sys.argv[2] == SERIALMSG_RUN:
    if op_run(s, sreqpkt) == True:
      print "Loaded image should be running now!"
    else:
      print "ERROR: Unable to run loaded image"
  elif sys.argv[2] == SERIALMSG_ERASE:
    if op_erase(s, sreqpkt) == True:
      print "Flash volume has been erased"
    else:
      print "ERROR: Unable to erase flash volume"
    
  elif sys.argv[2] == SERIALMSG_WRITE:
    input_file = file(sys.argv[3], 'rb')
    fileStats = os.stat(sys.argv[3])
    
    if fileStats[stat.ST_SIZE] <= DELUGE_VOLUME_SIZE:
      #sreqpkt = SerialReqPacket((SERIALMSG_LEDS, 0, 0, 0, []))
      #op_leds(s, sreqpkt)
      sreqpkt = SerialReqPacket((sys.argv[2], 0, 0, 0, []))
      if op_write(s, sreqpkt, input_file, fileStats[stat.ST_SIZE]) == True:
        print "File has been successfully transmitted (" + str(fileStats[stat.ST_SIZE]) + " bytes)"
      else:
        print "ERROR: Unable to transmit file"
      sreqpkt = SerialReqPacket((SERIALMSG_LEDS, 0, 0, 0, []))
      op_leds(s, sreqpkt)
    else:
      print "ERROR: File is larger than flash volume (" + DELUGE_VOLUME_SIZE + ")"
  
  elif sys.argv[2] == SERIALMSG_READ:
    data = op_print(s, sreqpkt, int(sys.argv[3]), int(sys.argv[4]))
    if data != True:
      print "ERROR: Unable to read the specified range"
    
  elif sys.argv[2] == SERIALMSG_CRC:
    remote_crc = op_crc(s, sreqpkt, int(sys.argv[3]), int(sys.argv[4]))
    if remote_crc != None:
      print_hex(0, remote_crc)
    else:
      print "ERROR: Unable to compute remote CRC"
