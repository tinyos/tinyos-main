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

// $Id: sim_packet.h,v 1.6 2010-06-29 22:07:51 scipio Exp $

#ifndef SIM_PACKET_H_INCLUDED
#define SIM_PACKET_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

  /*
   * sim_packet_t is a weird beast. It's a dummy type that can stand
   * in for message_t. We need to use sim_packet_t because gcc can't
   * understand message_t, due to its network types (nx). So the shim
   * code between Python and TOSSIM can't mention message_t.  Rather
   * than use a void*, the shim uses sim_packet_t in order to provide
   * some type checking. A sim_packet_t* is essentially a Python
   * friendly pointer to a message_t.
   */
  typedef struct sim_packet {} sim_packet_t;
  
  void sim_packet_set_source(sim_packet_t* msg, uint16_t src);
  uint16_t sim_packet_source(sim_packet_t* msg);
  
  void sim_packet_set_destination(sim_packet_t* msg, uint16_t dest);
  uint16_t sim_packet_destination(sim_packet_t* msg);
  
  void sim_packet_set_length(sim_packet_t* msg, uint8_t len);
  uint16_t sim_packet_length(sim_packet_t* msg);

  void sim_packet_set_type(sim_packet_t* msg, uint8_t type);
  uint8_t sim_packet_type(sim_packet_t* msg);

  uint8_t* sim_packet_data(sim_packet_t* msg);
  void sim_packet_set_strength(sim_packet_t* msg, uint16_t str);

  void sim_packet_deliver(int node, sim_packet_t* msg, sim_time_t t);
  uint8_t sim_packet_max_length(sim_packet_t* msg);

  sim_packet_t* sim_packet_allocate();
  void sim_packet_free(sim_packet_t* m);

  void sim_packet_set_dsn(sim_packet_t* msg, uint8_t dsn);
  uint8_t sim_packet_dsn(sim_packet_t* msg);

#ifdef __cplusplus
}
#endif
  
#endif // SIM_PACKET_H_INCLUDED
