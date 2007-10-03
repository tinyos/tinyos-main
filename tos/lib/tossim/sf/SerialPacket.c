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
