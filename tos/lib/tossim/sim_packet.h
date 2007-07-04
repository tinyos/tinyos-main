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

// $Id: sim_packet.h,v 1.5 2007-07-04 16:15:11 scipio Exp $

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

#ifdef __cplusplus
}
#endif
  
#endif // SIM_PACKET_H_INCLUDED
