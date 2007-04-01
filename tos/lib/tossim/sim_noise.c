/*
 * "Copyright (c) 2006 Stanford University. All rights reserved.
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
 * Implementation of all of the Hash-Based Learning primitives and utility
 * functions.
 *
 * @author Hyungjune Lee
 * @date   Oct 13 2006
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <sys/time.h>
#include <time.h>
#include "randomlib.h"
#include "hashtable.h"
#include "sim_noise.h"

uint32_t FreqKeyNum = 0;

sim_noise_node_t noiseData[TOSSIM_MAX_NODES];

static unsigned int sim_noise_hash(void *key);
static int sim_noise_eq(void *key1, void *key2);

void makeNoiseModel(uint16_t node_id);
void makePmfDistr(uint16_t node_id);
uint8_t search_bin_num(char noise);

void sim_noise_init()__attribute__ ((C, spontaneous))
{
  int j;
  
  //printf("Starting\n");
  
  for (j=0; j< TOSSIM_MAX_NODES; j++) {
    noiseData[j].noiseTable = create_hashtable(NOISE_HASHTABLE_SIZE, sim_noise_hash, sim_noise_eq);
    noiseData[j].noiseGenTime = 0;
    noiseData[j].noiseTrace = (char*)(malloc(sizeof(char) * NOISE_MIN_TRACE));
    noiseData[j].noiseTraceLen = NOISE_MIN_TRACE;
    noiseData[j].noiseTraceIndex = 0;

  }
  //printf("Done with sim_noise_init()\n");
}

void sim_noise_create_model(uint16_t node_id)__attribute__ ((C, spontaneous)) {
  makeNoiseModel(node_id);
  makePmfDistr(node_id);
}

char sim_real_noise(uint16_t node_id, uint32_t cur_t) {
  if (cur_t > noiseData[node_id].noiseTraceLen) {
    dbg("Noise", "Asked for noise element %u when there are only %u.\n", cur_t, noiseData[node_id].noiseTraceIndex);
    return 0;
  }
  return noiseData[node_id].noiseTrace[cur_t];
}

void sim_noise_trace_add(uint16_t node_id, char noiseVal)__attribute__ ((C, spontaneous)) {
  // Need to double size of trace arra
  if (noiseData[node_id].noiseTraceIndex ==
      noiseData[node_id].noiseTraceLen) {
    char* data = (char*)(malloc(sizeof(char) * noiseData[node_id].noiseTraceLen * 2));
    memcpy(data, noiseData[node_id].noiseTrace, noiseData[node_id].noiseTraceLen);
    free(noiseData[node_id].noiseTrace);
    noiseData[node_id].noiseTraceLen *= 2;
    noiseData[node_id].noiseTrace = data;
  }
  noiseData[node_id].noiseTrace[noiseData[node_id].noiseTraceIndex] = noiseVal;
  noiseData[node_id].noiseTraceIndex++;
}


uint8_t search_bin_num(char noise)__attribute__ ((C, spontaneous))
{
  uint8_t bin;
  bin = (noise-NOISE_MIN)/NOISE_QUANTIZE_INTERVAL + 1;
  return bin;
}

char search_noise_from_bin_num(int i)__attribute__ ((C, spontaneous))
{
  char noise;
  noise = NOISE_MIN + (i-1)*NOISE_QUANTIZE_INTERVAL;
  return noise;
}

static unsigned int sim_noise_hash(void *key) {
  char *pt = (char *)key;
  unsigned int hashVal = 0;
  int i;
  for (i=0; i< NOISE_HISTORY; i++) {
    hashVal = pt[i] + (hashVal << 6) + (hashVal << 16) - hashVal;
  }
  return hashVal;
}

static int sim_noise_eq(void *key1, void *key2) {
  return (memcmp((void *)key1, (void *)key2, NOISE_HISTORY) == 0);
}

void sim_noise_add(uint16_t node_id, char noise)__attribute__ ((C, spontaneous))
{
  int i;
  struct hashtable *pnoiseTable = noiseData[node_id].noiseTable;
  char *key = noiseData[node_id].key;
  sim_noise_hash_t *noise_hash;
  noise_hash = (sim_noise_hash_t *)hashtable_search(pnoiseTable, key);
  dbg("Insert,HashZeroDebug", "Adding noise value %hhi\n", noise);
  if (noise_hash == NULL)	{
    noise_hash = (sim_noise_hash_t *)malloc(sizeof(sim_noise_hash_t));
    memcpy((void *)(noise_hash->key), (void *)key, NOISE_HISTORY);
    
    noise_hash->numElements = 0;
    noise_hash->size = NOISE_DEFAULT_ELEMENT_SIZE;
    noise_hash->elements = (char *)malloc(sizeof(char)*noise_hash->size);
    memset((void *)noise_hash->elements, 0, sizeof(char)*noise_hash->size);

    noise_hash->flag = 0;
    for(i=0; i<NOISE_BIN_SIZE; i++) {
	noise_hash->dist[i] = 0;
    }
    hashtable_insert(pnoiseTable, key, noise_hash);
    dbg("Insert", "Inserting %p into table %p with key ", noise_hash, pnoiseTable);
    {
      int ctr;
      for(ctr = 0; ctr < NOISE_HISTORY; ctr++)
	dbg_clear("Insert", "%0.3hhi ", key[ctr]);
    }
    dbg_clear("Insert", "\n");
  }

  if (noise_hash->numElements == noise_hash->size)
    {
      char *newElements;
      int newSize = (noise_hash->size)*2;

      newElements = (char *)malloc(sizeof(char)*newSize);
      memcpy(newElements, noise_hash->elements, noise_hash->size);
      free(noise_hash->elements);
      noise_hash->elements = newElements;
      noise_hash->size = newSize;
    }

  noise_hash->elements[noise_hash->numElements] = noise;
  noise_hash->numElements++;
}

void sim_noise_dist(uint16_t node_id)__attribute__ ((C, spontaneous))
{
  int i;
  uint8_t bin;
  float cmf = 0;
  struct hashtable *pnoiseTable = noiseData[node_id].noiseTable;
  char *key = noiseData[node_id].key;
  char *freqKey = noiseData[node_id].freqKey;
  sim_noise_hash_t *noise_hash;
  noise_hash = (sim_noise_hash_t *)hashtable_search(pnoiseTable, key);

  if (noise_hash->flag == 1)
    return;

  for (i=0; i < NOISE_BIN_SIZE; i++) {
    noise_hash->dist[i] = 0.0;
  }
  
  for (i=0; i< noise_hash->numElements; i++)
    {
      float val;
      bin = search_bin_num(noise_hash->elements[i]) - 1;
      val = noise_hash->dist[bin];
      val += (float)1.0;
      noise_hash->dist[bin] = val;
    }

  for (i=0; i < NOISE_BIN_SIZE ; i++)
    {
      noise_hash->dist[i] = (noise_hash->dist[i])/(noise_hash->numElements);
      cmf += noise_hash->dist[i];
      noise_hash->dist[i] = cmf;
    }
  noise_hash->flag = 1;

  //Find the most frequent key and store it in noiseData[node_id].freqKey[].
  if (noise_hash->numElements > FreqKeyNum)
    {
      int j;
      FreqKeyNum = noise_hash->numElements;
      memcpy((void *)freqKey, (void *)key, NOISE_HISTORY);
      dbg("HashZeroDebug", "Setting most frequent key (%i): ", (int) FreqKeyNum);
      for (j = 0; j < NOISE_HISTORY; j++) {
	dbg_clear("HashZeroDebug", "[%hhu] ", key[j]);
      }
      dbg_clear("HashZeroDebug", "\n");
    }
}

void arrangeKey(uint16_t node_id)__attribute__ ((C, spontaneous))
{
  char *pKey = noiseData[node_id].key;
  memcpy(pKey, pKey+1, NOISE_HISTORY-1);

}

/*
 * After makeNoiseModel() is done, make PMF distribution for each bin.
 */
void makePmfDistr(uint16_t node_id)__attribute__ ((C, spontaneous))
{
  int i;
  char *pKey = noiseData[node_id].key;
  char *fKey = noiseData[node_id].freqKey;

  FreqKeyNum = 0;
  for(i=0; i<NOISE_HISTORY; i++) {
    pKey[i] = search_bin_num(noiseData[node_id].noiseTrace[i]);
  }
  sim_noise_dist(node_id);
  arrangeKey(node_id);
  for(i = NOISE_HISTORY; i < noiseData[node_id].noiseTraceIndex; i++) {
    if (i == NOISE_HISTORY) {
      printf("Inserting first element.\n");
    }
    pKey[NOISE_HISTORY-1] = search_bin_num(noiseData[node_id].noiseTrace[i]);
    sim_noise_dist(node_id);
    arrangeKey(node_id);
  }

  dbg_clear("HASH", "FreqKey = ");
  for (i=0; i< NOISE_HISTORY ; i++)
    {
      dbg_clear("HASH", "%d,", fKey[i]);
    }
  dbg_clear("HASH", "\n");
}

int dummy;
void sim_noise_alarm() {
  dummy = 5;
}

char sim_noise_gen(uint16_t node_id)__attribute__ ((C, spontaneous))
{
  int i;
  int noiseIndex = 0;
  char noise;
  struct hashtable *pnoiseTable = noiseData[node_id].noiseTable;
  char *pKey = noiseData[node_id].key;
  char *fKey = noiseData[node_id].freqKey;
  double ranNum = RandomUniform();
  sim_noise_hash_t *noise_hash;
  noise_hash = (sim_noise_hash_t *)hashtable_search(pnoiseTable, pKey);

  if (noise_hash == NULL) {
    sim_noise_alarm();
    noise = 0;
    dbg_clear("HASH", "(N)Noise\n");
    dbg("HashZeroDebug", "Defaulting to common hash.\n");
    memcpy((void *)pKey, (void *)fKey, NOISE_HISTORY);
    noise_hash = (sim_noise_hash_t *)hashtable_search(pnoiseTable, pKey);
  }
  
  dbg_clear("HASH", "Key = ");
  for (i=0; i< NOISE_HISTORY ; i++) {
    dbg_clear("HASH", "%d,", pKey[i]);
  }
  dbg_clear("HASH", "\n");
  
  dbg("HASH", "Printing Key\n");
  dbg("HASH", "noise_hash->numElements=%d\n", noise_hash->numElements);
  if (noise_hash->numElements == 1) {
    noise = noise_hash->elements[0];
    dbg_clear("HASH", "(E)Noise = %d\n", noise);			
    return noise;
  }
  
  for (i = 0; i < NOISE_BIN_SIZE - 1; i++) {
    dbg("HASH", "IN:for i=%d\n", i);
    if (i == 0) {	
      if (ranNum <= noise_hash->dist[i]) {
	noiseIndex = i;
	dbg_clear("HASH", "Selected Bin = %d -> ", i+1);
	break;
      }
    }
    else if ( (noise_hash->dist[i-1] < ranNum) && 
	      (ranNum <= noise_hash->dist[i])   ) {
      noiseIndex = i;
      dbg_clear("HASH", "Selected Bin = %d -> ", i+1);
      break;
    }
  }
  dbg("HASH", "OUT:for i=%d\n", i);
  
  noise = search_noise_from_bin_num(i+1);
  dbg_clear("HASH", "(B)Noise = %d\n", noise);
  return noise;
}

char sim_noise_generate(uint16_t node_id, uint32_t cur_t)__attribute__ ((C, spontaneous)) {
  uint32_t i;
  uint32_t prev_t;
  uint32_t delta_t;
  char *noiseG;
  char noise;

  prev_t = noiseData[node_id].noiseGenTime;

  if ( (0<= cur_t) && (cur_t < NOISE_HISTORY) ) {
    noiseData[node_id].noiseGenTime = cur_t;
    noiseData[node_id].key[cur_t] = search_bin_num(noiseData[node_id].noiseTrace[cur_t]);
    noiseData[node_id].lastNoiseVal = noiseData[node_id].noiseTrace[cur_t];
    return noiseData[node_id].noiseTrace[cur_t];
  }

  if (prev_t == 0)
    delta_t = cur_t - (NOISE_HISTORY-1);
  else
    delta_t = cur_t - prev_t;
  
  dbg_clear("HASH", "delta_t = %d\n", delta_t);
  
  if (delta_t == 0)
    noise = noiseData[node_id].lastNoiseVal;
  else {
    noiseG = (char *)malloc(sizeof(char)*delta_t);
    
    for(i=0; i< delta_t; i++) {
      noiseG[i] = sim_noise_gen(node_id);
      arrangeKey(node_id);
      noiseData[node_id].key[NOISE_HISTORY-1] = search_bin_num(noiseG[i]);
    }
    noise = noiseG[delta_t-1];
    noiseData[node_id].lastNoiseVal = noise;
    
    free(noiseG);
  }
  noiseData[node_id].noiseGenTime = cur_t;
  if (noise == 0) {
    dbg("HashZeroDebug", "Generated noise of zero.\n");
  }
  return noise;
}

/* 
 * When initialization process is going on, make noise model by putting
 * experimental noise values.
 */
void makeNoiseModel(uint16_t node_id)__attribute__ ((C, spontaneous)) {
  int i;
  for(i=0; i<NOISE_HISTORY; i++) {
    noiseData[node_id].key[i] = search_bin_num(noiseData[node_id].noiseTrace[i]);
  }
  
  sim_noise_add(node_id, noiseData[node_id].noiseTrace[NOISE_HISTORY]);
  arrangeKey(node_id);
  
  for(i = NOISE_HISTORY; i < noiseData[node_id].noiseTraceIndex; i++) {
    noiseData[node_id].key[NOISE_HISTORY-1] = search_bin_num(noiseData[node_id].noiseTrace[i]);
    sim_noise_add(node_id, noiseData[node_id].noiseTrace[i+1]);
    arrangeKey(node_id);
  }
}


