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
 * @date   Dec 10 2005
 */

#include <packet.h>
#include <sim_packet.h>

Packet::Packet() {
  msgPtr = sim_packet_allocate();
  allocated = 1;
}

Packet::Packet(sim_packet_t* m) {
  if (m != NULL) {
    msgPtr = m;
    allocated = 0;
  }
  else {
    msgPtr = sim_packet_allocate();
    allocated = 1;
  }
}

Packet::~Packet() {
  if (allocated) {
    sim_packet_free(msgPtr);
  }
}

void Packet::setSource(int src) {
  sim_packet_set_source(msgPtr, (uint16_t)src);
}
int Packet::source() {
  return sim_packet_source(msgPtr);
}

void Packet::setDestination(int dest) {
  sim_packet_set_destination(msgPtr, (uint16_t)dest);
}
int Packet::destination() {
  return sim_packet_destination(msgPtr);
}

void Packet::setLength(int len) {
  sim_packet_set_length(msgPtr, (uint8_t)len);
}
int Packet::length() {
  return sim_packet_length(msgPtr);
}

void Packet::setType(int type) {
  sim_packet_set_type(msgPtr, (uint8_t)type);
}
int Packet::type() {
  return sim_packet_type(msgPtr);
}

char* Packet::data() {
  char* val =  (char*)sim_packet_data(msgPtr);
  return val;
}

void Packet::setData(char* data, int len) {
  len = (len > maxLength())? maxLength():len;
  memcpy(sim_packet_data(msgPtr), data, len);
  setLength(len);
}

int Packet::maxLength() {
  return (int)sim_packet_max_length(msgPtr);
}

void Packet::setStrength(int str) {
  sim_packet_set_strength(msgPtr, (uint16_t)str);
}

sim_packet_t* Packet::getPacket() {
  return msgPtr;
}

void Packet::deliver(int node, long long int t) {
  sim_packet_deliver(node, msgPtr, t);
}

void Packet::deliverNow(int node) {
  deliver(node, 0);
}
