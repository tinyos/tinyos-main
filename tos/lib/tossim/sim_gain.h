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
 * The C functions that allow TOSSIM-side code to access the SimMoteP
 * component.
 *
 * @author Philip Levis
 * @date   Nov 22 2005
 */


// $Id: sim_gain.h,v 1.3 2006-11-07 19:31:21 scipio Exp $



#ifndef SIM_GAIN_H_INCLUDED
#define SIM_GAIN_H_INCLUDED


#ifdef __cplusplus
extern "C" {
#endif

typedef struct gain_entry {
  int mote;
  double gain;
  struct gain_entry* next;  
} gain_entry_t;
  
void sim_gain_add(int src, int dest, double gain);
double sim_gain_value(int src, int dest);
bool sim_gain_connected(int src, int dest);
void sim_gain_remove(int src, int dest);
void sim_gain_set_noise_floor(int node, double mean, double range);
double sim_gain_sample_noise(int node);
double sim_gain_noise_mean(int node);
double sim_gain_noise_range(int node);

void sim_gain_set_sensitivity(double value);
double sim_gain_sensitivity();
  
gain_entry_t* sim_gain_first(int src);
gain_entry_t* sim_gain_next(gain_entry_t* e);
  
#ifdef __cplusplus
}
#endif
  
#endif // SIM_GAIN_H_INCLUDED
