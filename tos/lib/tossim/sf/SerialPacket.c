/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *
 * Injecting packets into TOSSIM.
 *
 * @author Philip Levis
 * @author Chad Metcalf
 * @date   July 15 2007
 */

#include <SerialPacket.h>
#include <sim_serial_packet.h>

SerialPacket::SerialPacket() {
  msgPtr = sim_serial_packet_allocate();
  allocated = 1;
}

SerialPacket::SerialPacket(sim_serial_packet_t* m) {
  if (m != NULL) {
    msgPtr = m;
    allocated = 0;
  }
  else {
    msgPtr = sim_serial_packet_allocate();
    allocated = 1;
  }
}

SerialPacket::~SerialPacket() {
  if (allocated) {
    sim_serial_packet_free(msgPtr);
  }
}

void SerialPacket::setDestination(int dest) {
  sim_serial_packet_set_destination(msgPtr, (uint16_t)dest);
}
int SerialPacket::destination() {
  return sim_serial_packet_destination(msgPtr);
}

void SerialPacket::setLength(int len) {
  sim_serial_packet_set_length(msgPtr, (uint8_t)len);
}
int SerialPacket::length() {
  return sim_serial_packet_length(msgPtr);
}

void SerialPacket::setType(int type) {
  sim_serial_packet_set_type(msgPtr, (uint8_t)type);
}
int SerialPacket::type() {
  return sim_serial_packet_type(msgPtr);
}

char* SerialPacket::data() {
  char* val =  (char*)sim_serial_packet_data(msgPtr);
  return val;
}

void SerialPacket::setData(char* data, int len) {
  len = (len > maxLength())? maxLength():len;
  memcpy(sim_serial_packet_data(msgPtr), data, len);
  setLength(len);
}

int SerialPacket::maxLength() {
  return (int)sim_serial_packet_max_length(msgPtr);
}

sim_serial_packet_t* SerialPacket::getPacket() {
  return msgPtr;
}

void SerialPacket::deliver(int node, long long int t) {
  sim_serial_packet_deliver(node, msgPtr, t);
}

void SerialPacket::deliverNow(int node) {
  deliver(node, 0);
}
