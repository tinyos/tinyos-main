/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
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
