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
 * Implementation of all of the basic TOSSIM primitives and utility
 * functions.
 *
 * @author Philip Levis
 * @date   Nov 22 2005
 */

// $Id: sim_tossim.c,v 1.7 2007-10-26 01:47:12 scipio Exp $


#include <sim_tossim.h>
#include <sim_event_queue.h>
#include <sim_mote.h>
#include <stdlib.h>
#include <sys/time.h>

#include <sim_noise.h> //added by HyungJune Lee

static sim_time_t sim_ticks;
static unsigned long current_node;
static int sim_seed;

static int __nesc_nido_resolve(int mote, char* varname, uintptr_t* addr, size_t* size);

void sim_init() __attribute__ ((C, spontaneous)) {
  sim_queue_init();
  sim_log_init();
  sim_log_commit_change();
  sim_noise_init(); //added by HyungJune Lee

  {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    // Need to make sure we don't pass zero to seed simulation.
    // But in case some weird timing factor causes usec to always
    // be zero, default to tv_sec. Note that the explicit
    // seeding call also has a check for zero. Thanks to Konrad
    // Iwanicki for finding this. -pal
    if (tv.tv_usec != 0) {
      sim_random_seed(tv.tv_usec);
    }
    else {
      sim_random_seed(tv.tv_sec);
    }
  } 
}

void sim_end() __attribute__ ((C, spontaneous)) {
  sim_queue_init();
}



int sim_random() __attribute__ ((C, spontaneous)) {
  uint32_t mlcg,p,q;
  uint64_t tmpseed;
  tmpseed =  (uint64_t)33614U * (uint64_t)sim_seed;
  q = tmpseed;    /* low */
  q = q >> 1;
  p = tmpseed >> 32 ;             /* hi */
  mlcg = p + q;
  if (mlcg & 0x80000000) {
    mlcg = mlcg & 0x7FFFFFFF;
    mlcg++;
  }
  sim_seed = mlcg;
  return mlcg;
}

void sim_random_seed(int seed) __attribute__ ((C, spontaneous)) {
  // A seed of zero wedges on zero, so use 1 instead.
  if (seed == 0) {
    seed = 1;
  }
  sim_seed = seed;
}

sim_time_t sim_time() __attribute__ ((C, spontaneous)) {
  return sim_ticks;
}
void sim_set_time(sim_time_t t) __attribute__ ((C, spontaneous)) {
  sim_ticks = t;
}

sim_time_t sim_ticks_per_sec() __attribute__ ((C, spontaneous)) {
  return 10000000000ULL;
}

unsigned long sim_node() __attribute__ ((C, spontaneous)) {
  return current_node;
}
void sim_set_node(unsigned long node) __attribute__ ((C, spontaneous)) {
  current_node = node;
  TOS_NODE_ID = node;
}

bool sim_run_next_event() __attribute__ ((C, spontaneous)) {
  bool result = FALSE;
  if (!sim_queue_is_empty()) {
    sim_event_t* event = sim_queue_pop();
    sim_set_time(event->time);
    sim_set_node(event->mote);

    // Need to test whether function pointers are for statically
    // allocted events that are zeroed out on reboot
    dbg("Tossim", "CORE: popping event 0x%p for %i at %llu with handler %p... ", event, sim_node(), sim_time(), event->handle);
    if ((sim_mote_is_on(event->mote) || event->force) &&
	event->handle != NULL) {
      result = TRUE;
      dbg_clear("Tossim", " mote is on (or forced event), run it.\n");
      event->handle(event);
    }
    else {
      dbg_clear("Tossim", "\n");
    }
    if (event->cleanup != NULL) {
      event->cleanup(event);
    }
  }

  return result;
}

int sim_print_time(char* buf, int len, sim_time_t ftime) __attribute__ ((C, spontaneous)) {
  int hours;
  int minutes;
  int seconds;
  sim_time_t  secondBillionths;

  secondBillionths = (ftime % sim_ticks_per_sec());
  if (sim_ticks_per_sec() > (sim_time_t)1000000000) {
    secondBillionths /= (sim_ticks_per_sec() / (sim_time_t)1000000000);
  }
  else {
    secondBillionths *= ((sim_time_t)1000000000 / sim_ticks_per_sec());
  }

  seconds = (int)(ftime / sim_ticks_per_sec());
  minutes = seconds / 60;
  hours = minutes / 60;
  seconds %= 60;
  minutes %= 60;
  buf[len-1] = 0;
  return snprintf(buf, len - 1, "%i:%i:%i.%09llu", hours, minutes, seconds, secondBillionths);
}

int sim_print_now(char* buf, int len) __attribute__ ((C, spontaneous)) {
  return sim_print_time(buf, len, sim_time());
}

char simTimeBuf[128];
char* sim_time_string() __attribute__ ((C, spontaneous)) {
  sim_print_now(simTimeBuf, 128);
  return simTimeBuf;
}

void sim_add_channel(char* channel, FILE* file) __attribute__ ((C, spontaneous)) {
  sim_log_add_channel(channel, file);
}

bool sim_remove_channel(char* channel, FILE* file)  __attribute__ ((C, spontaneous)) {
  return sim_log_remove_channel(channel, file);
}
