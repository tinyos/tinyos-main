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
 * Implementation of all of the SNIST primitives and utility
 * functions.
 *
 * @author Hyungjune Lee
 * @date   Oct 13 2006
 */

// $Id: sim_noise.h,v 1.6 2007-08-05 22:29:46 scipio Exp $

#ifndef _SIM_NOISE_HASH_H_
#define _SIM_NOISE_HASH_H_

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

// BIN_SIZE (the number of bins) has a + 1 in case the range is not
// evenly divisible by INTERVAL -pal 5.aug.07
enum {
  NOISE_MIN = -115,
  NOISE_MAX = -5,
  NOISE_MIN_QUANTIZE = -115,
  NOISE_QUANTIZE_INTERVAL = 5,
  NOISE_BIN_SIZE = ((NOISE_MAX - NOISE_MIN) / NOISE_QUANTIZE_INTERVAL) + 1,
  NOISE_HISTORY = 20,
  NOISE_DEFAULT_ELEMENT_SIZE = 8,
  NOISE_HASHTABLE_SIZE = 128,
  NOISE_MIN_TRACE = 128, 
};
  
typedef struct sim_noise_hash_t {
  char key[NOISE_HISTORY];
  int numElements;
  int size;
  char *elements;
  char flag;
  float dist[NOISE_BIN_SIZE];
} sim_noise_hash_t;

typedef struct sim_noise_node_t {
  char key[NOISE_HISTORY];
  char freqKey[NOISE_HISTORY];
  char lastNoiseVal;
  uint32_t noiseGenTime;
  struct hashtable *noiseTable;
  char* noiseTrace;
  uint32_t noiseTraceLen;
  uint32_t noiseTraceIndex;
  bool generated;
} sim_noise_node_t;

void sim_noise_init();
char sim_real_noise(uint16_t node_id, uint32_t cur_t);
char sim_noise_generate(uint16_t node_id, uint32_t cur_t);
void sim_noise_trace_add(uint16_t node_id, char val);
void sim_noise_create_model(uint16_t node_id);
  
#ifdef __cplusplus
}
#endif
  
#endif // _SIM_NOISE_HASH_H_

