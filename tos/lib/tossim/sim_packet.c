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
 * TOSSIM packet abstract data type, so C++ code can call into nesC
 * code that does the native-to-network type translation.
 *
 * @author Philip Levis
 * @date   Jan 2 2006
 */

// $Id: sim_packet.c,v 1.6 2010-06-29 22:07:51 scipio Exp $

#include <sim_packet.h>
#include <message.h>

// NOTE: This function is defined in lib/tossim/ActiveMessageC. It
// has to be predeclared here because it is defined within that component.
void active_message_deliver(int node, message_t* m, sim_time_t t);

static tossim_header_t* getHeader(message_t* msg) {
  return (tossim_header_t*)(msg->data - sizeof(tossim_header_t));
}

void sim_packet_set_source(sim_packet_t* msg, uint16_t src)__attribute__ ((C, spontaneous)) {
  tossim_header_t* hdr = getHeader((message_t*)msg);
  hdr->src = src;
}

uint16_t sim_packet_source(sim_packet_t* msg)__attribute__ ((C, spontaneous)) {
  tossim_header_t* hdr = getHeader((message_t*)msg);
  return hdr->src;
}

void sim_packet_set_destination(sim_packet_t* msg, uint16_t dest)__attribute__ ((C, spontaneous)) {
  tossim_header_t* hdr = getHeader((message_t*)msg);
  hdr->dest = dest;
}

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
