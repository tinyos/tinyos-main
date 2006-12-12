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
 * TOSSIM packet abstract data type, so C++ code can call into nesC
 * code that does the native-to-network type translation.
 *
 * @author Philip Levis
 * @date   Jan 2 2006
 */

// $Id: sim_packet.c,v 1.4 2006-12-12 18:23:35 vlahan Exp $

#include <sim_packet.h>
#include <message.h>

// NOTE: This function is defined in lib/tossim/ActiveMessageC. It
// has to be predeclared here because it is defined within that component.
void active_message_deliver(int node, message_t* m, sim_time_t t);

static tossim_header_t* getHeader(message_t* msg) {
  return (tossim_header_t*)(msg->data - sizeof(tossim_header_t));
}

void sim_packet_set_destination(sim_packet_t* msg, uint16_t dest)__attribute__ ((C, spontaneous)) {
  tossim_header_t* hdr = getHeader((message_t*)msg);
  hdr->dest = dest;
}__attribute__ ((C, spontaneous))

uint16_t sim_packet_destination(sim_packet_t* msg)__attribute__ ((C, spontaneous)) {
  tossim_header_t* hdr = getHeader((message_t*)msg);
  return hdr->dest;
}
  
void sim_packet_set_length(sim_packet_t* msg, uint8_t length)__attribute__ ((C, spontaneous)) {
  tossim_header_t* hdr = getHeader((message_t*)msg);
  hdr->length = length;
}
uint16_t sim_packet_length(sim_packet_t* msg)__attribute__ ((C, spontaneous)) {
  tossim_header_t* hdr = getHeader((message_t*)msg);
  return hdr->length;
}

void sim_packet_set_type(sim_packet_t* msg, uint8_t type) __attribute__ ((C, spontaneous)){
  tossim_header_t* hdr = getHeader((message_t*)msg);
  hdr->type = type;
}

uint8_t sim_packet_type(sim_packet_t* msg) __attribute__ ((C, spontaneous)){
  tossim_header_t* hdr = getHeader((message_t*)msg);
  return hdr->type;
}

uint8_t* sim_packet_data(sim_packet_t* p) __attribute__ ((C, spontaneous)){
  message_t* msg = (message_t*)p;
  return (uint8_t*)&msg->data;
}
void sim_packet_set_strength(sim_packet_t* p, uint16_t str) __attribute__ ((C, spontaneous)){
  message_t* msg = (message_t*)p;
  tossim_metadata_t* md = (tossim_metadata_t*)(&msg->metadata);
  md->strength = str;
}
void sim_packet_deliver(int node, sim_packet_t* msg, sim_time_t t) __attribute__ ((C, spontaneous)){
  if (t < sim_time()) {
    t = sim_time();
  }
  dbg("Packet", "sim_packet.c: Delivering packet %p to %i at %llu\n", msg, node, t);
  active_message_deliver(node, (message_t*)msg, t);
}
  
uint8_t sim_packet_max_length(sim_packet_t* msg) __attribute__ ((C, spontaneous)){
  return TOSH_DATA_LENGTH;
}

sim_packet_t* sim_packet_allocate () __attribute__ ((C, spontaneous)){
  return (sim_packet_t*)malloc(sizeof(message_t));
}

void sim_packet_free(sim_packet_t* p) __attribute__ ((C, spontaneous)) {
  printf("sim_packet.c: Freeing packet %p\n", p);
  free(p);
}
