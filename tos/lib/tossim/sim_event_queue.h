// $Id: sim_event_queue.h,v 1.5 2008-06-11 00:46:26 razvanm Exp $

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
