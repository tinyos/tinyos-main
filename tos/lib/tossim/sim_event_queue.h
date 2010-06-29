// $Id: sim_event_queue.h,v 1.6 2010-06-29 22:07:51 scipio Exp $

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
 * - Neither the name of the copyright holders nor the names of
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
 * The event queue is the core of the mote side of TOSSIM. It is a
 * wrapper around the underlying heap. Unlike the 1.x version, it is
 * not re-entrant: merging the Python console and TOSSIM means that
 * functionality like packet injection/reception from external tools
 * is on the Python side.
 *
 * @author Phil Levis
 * @date   November 22 2005
 */


#ifndef SIM_EVENT_QUEUE_H_INCLUDED
#define SIM_EVENT_QUEUE_H_INCLUDED

#include <sim_tossim.h>

struct sim_event;
typedef struct sim_event sim_event_t;

struct sim_event {
  sim_time_t time;
  unsigned long  mote;
  bool force; // Whether this event type should always be executed
            // even if a mote is "turned off"
  bool cancelled; // Whether this event has been cancelled
  void* data;
  
  void (*handle)(sim_event_t* e);
  void (*cleanup)(sim_event_t* e);
};

sim_event_t* sim_queue_allocate_event();

void sim_queue_init();
void sim_queue_insert(sim_event_t* event);
bool sim_queue_is_empty();
long long int sim_queue_peek_time();
sim_event_t* sim_queue_pop();

void sim_queue_cleanup_none(sim_event_t* e);
void sim_queue_cleanup_event(sim_event_t* e);
void sim_queue_cleanup_data(sim_event_t* e) ;
void sim_queue_cleanup_total(sim_event_t* e);


#endif // EVENT_QUEUE_H_INCLUDED
