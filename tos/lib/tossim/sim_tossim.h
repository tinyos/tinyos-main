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

// $Id: sim_tossim.h,v 1.4 2006-12-12 18:23:35 vlahan Exp $

#ifndef SIM_TOSSIM_H_INCLUDED
#define SIM_TOSSIM_H_INCLUDED

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef long long int sim_time_t;
  
void sim_init();
void sim_start();
void sim_end();

void sim_random_seed(int seed);
int sim_random();
  
sim_time_t sim_time();
void sim_set_time(sim_time_t time);
sim_time_t sim_ticks_per_sec();
  
unsigned long sim_node();
void sim_set_node(unsigned long node);

int sim_print_time(char* buf, int bufLen, sim_time_t time);
int sim_print_now(char* buf, int bufLen);
char* sim_time_string();

void sim_add_channel(char* channel, FILE* file);
bool sim_remove_channel(char* channel, FILE* file);
  
bool sim_run_next_event();

  
#ifdef __cplusplus
}
#endif
  
#endif // SIM_TOSSIM_H_INCLUDED
