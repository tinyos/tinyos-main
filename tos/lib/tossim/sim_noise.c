/*
 * Copyright (c) 2006 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * The C functions for accessing TOSSIM's noise simulation data
 * structures.
 *
 * @author Philip Levis
 * @date   Mar 2 2007
 */


// $Id: sim_noise.c,v 1.2 2007-03-07 01:07:10 scipio Exp $


#include <tos.h>

#include <sim_noise.h>
#include <hashtable.h>

#ifdef TESTING 
#include <hashtable.c>
#include <stdio.h>
#include <stdlib.h>
#define TOSSIM_MAX_NODE 20
sim_time_t sim_mote_start_time(int mote) {
  return 37;
}
sim_time_t sim_ticks_per_sec() {
  return 10000000;
}
#endif

typedef struct noise_distribution {
  int minValue;
  int numBuckets;
  int discretization;
  int sum;
  int* counts;
} noise_distribution_t;

typedef struct noise_model {
  uint32_t historyLength;        // The history "k" of the model
  uint32_t sampleRateHz;         // The rate at which samples change
  hashtable_t* table;            // A pointer to the distribution hashtable
  noise_distribution_t* common;  // Most common distribution
  double* firstReadings;         // An array of the first k values of the trace
  double* lastReadings;          // An array of the last k values observed
  uint32_t lastReading;          // When was the last value observed
  uint8_t discretization;        // The discretization unit for readings
  sim_time_t increment;          // The sim_time between samples (derived from sample rate)
  uint16_t bins;                 // The number of noise value bins (range / discretization)
  double minNoise;               // The minimum noise value
  bool dirty;                    // Has data been added to the model so it needs to be recomputed?
} noise_model_t;

noise_model_t models[TOSSIM_MAX_NODE];

void clear_data(uint32_t mote);
void add_data(uint32_t mote, double value);
void generate_model(int mote);
static unsigned int sim_noise_hash(void* key);
static int sim_noise_equal(void* key1, void* key2);
noise_distribution_t* create_noise_distribution(int mote);
void add_val_to_distribution(noise_distribution_t* dist, int value);

int make_discrete(double value, uint8_t discretization) {
  int val = (int)value;
  val /= discretization;
  val *= discretization;
}

void create_model(uint32_t mote, uint32_t sampleRate, uint32_t historyLength, uint8_t discretization, uint16_t bins, double minNoise) {
  int i;
  if (mote < TOSSIM_MAX_NODES) {
    models[mote].historyLength = historyLength;
    models[mote].sampleRateHz = sampleRate;
    models[mote].table = create_hashtable(10240, sim_noise_hash, sim_noise_equal);
    models[mote].lastReadings = (double*)(malloc(sizeof(double) * historyLength));
    models[mote].discretization = discretization;
    models[mote].lastReading = historyLength - 1;
    for (i = 0; i < historyLength; i++) {
      models[mote].lastReadings[i] = 0.0;
    }
    models[mote].dirty = FALSE;
    models[mote].bins = bins;
    models[mote].minNoise = minNoise;
    models[mote].increment = sim_ticks_per_sec() / models[mote].sampleRateHz;
    clear_data(mote);
  }
}

void clear_model(uint32_t mote) {
  clear_data(mote);
  if (models[mote].table != NULL) {
    hashtable_destroy(models[mote].table, 1);
    models[mote].table = NULL;
  }
  if (models[mote].lastReadings != NULL) {
    free(models[mote].lastReadings);
    models[mote].lastReadings = NULL;
  }
}

void add_reading(int mote, double value) {
  add_data(mote, value);
  models[mote].dirty = 1;
}

char* hashString = NULL;
int hashStringLength = 0;

#define SAMPLE_STR_LEN 10
char* generateHashString(double* readings, int len, int discretization) {
  char* ptr;
  int i;
  if (hashStringLength < len * SAMPLE_STR_LEN) {
    int newLen = (len * SAMPLE_STR_LEN);
    free(hashString);
    hashString = (char*)malloc(sizeof(char) * newLen + 1);
    hashStringLength = newLen;
  }
  ptr = hashString;
  for (i = 0; i < len; i++) {
    int val = make_discrete(readings[i], discretization);
    ptr += snprintf(ptr, SAMPLE_STR_LEN, "%i ", val);
  }
  return hashString;
}
static int sim_seed = 2342;

int sim_random() {
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

double sampleDistribution(noise_distribution_t* dist) {
  double rval = 0.0;
  if (dist->sum == 0) {
    return rval;
  }
  else {
    int which = sim_random() % dist->sum;
    int total = 0;
    int i;
    printf("%i of ", which);
    for (i = 0; i < dist->numBuckets; i++) {
      printf("[%i] ", dist->counts[i]);
    }
    printf("\n");
    for (i = 0; i < dist->numBuckets; i++) {
      total += dist->counts[i];
      if (total > which) {
	printf("Sampling %i\n", i);
	rval = (i * dist->discretization) + dist->minValue;
	break;
      }
    }
  }
  // Should never reach this
  return rval;
}

void appendReading(int mote, double reading) {
  int size = ((models[mote].historyLength - 1) * sizeof(double));
  memcpy(models[mote].lastReadings, models[mote].lastReadings + 1, size);
  models[mote].lastReadings[models[mote].historyLength - 1] = reading;
  models[mote].lastReading++;
}

void generateReading(int mote) {
  char* str = generateHashString(models[mote].lastReadings, models[mote].historyLength, models[mote].discretization) ;
  printf("%s : ", str);
  noise_distribution_t* noise = (noise_distribution_t*)hashtable_search(models[mote].table, hashString);
  if (noise == NULL) {
    printf("Using default distribution: ");
    noise = models[mote].common;
  }
  double reading = sampleDistribution(noise);
  //printf("reading: %f\n", reading);
  appendReading(mote, reading);
}

void generateReadings(int mote, uint64_t count) {
  uint64_t i;
  for (i = 0; i < count; i++) {
    generateReading(mote);
  }
}

double getSample(int mote, sim_time_t time) {
  int64_t readingNo;
  int64_t readingCount;
  sim_time_t timePassed = time - sim_mote_start_time(mote);
  noise_model_t* model = &models[mote];
  if (timePassed < 0) {
    return (double)make_discrete(model->firstReadings[0], model->discretization);
  }
  if (model->dirty) {
    generate_model(mote);
  }
  readingNo = timePassed / (uint64_t)model->increment;

  if (readingNo < model->historyLength) {
    return make_discrete(model->firstReadings[readingNo], model->discretization);
  }
  
  readingCount = readingNo - model->lastReading;
  generateReadings(mote, readingCount);
  return make_discrete(model->lastReadings[0], model->discretization);
}
  
  
  
typedef struct noise_data {
  uint32_t size;
  uint32_t maxSize;
  double* readings;
} noise_data_t;

noise_data_t data[TOSSIM_MAX_NODE];

void init_data(uint32_t mote) {
  if (mote < TOSSIM_MAX_NODE) {
    data[mote].size = 0;
    data[mote].maxSize = 1024;
    data[mote].readings = (double*)(malloc(sizeof(double) * 1024));
  }
}
 
void clear_data(uint32_t mote) {
  if (mote < TOSSIM_MAX_NODE) {
    if (data[mote].readings != NULL) {
      free(data[mote].readings);
      data[mote].readings = NULL;
    }
    init_data(mote);
  }
}

void add_data(uint32_t mote, double value) {
  if (mote < TOSSIM_MAX_NODE) {
    if (data[mote].size == data[mote].maxSize) {
      double* ndata = (double*)malloc(sizeof(double) * 2 * data[mote].maxSize);
      memcpy(ndata, data[mote].readings, data[mote].size * sizeof(double));
      free(data[mote].readings);
      data[mote].readings = ndata;
      data[mote].maxSize *= 2;
    }
    data[mote].readings[data[mote].size] = value;
    data[mote].size++;
  }
}



static unsigned int sim_noise_hash(void* key) {
  char* str = (char*)key;
  unsigned int hashVal = 0;
  int c;
  
  while ((c = *str++))
    hashVal = c + (hashVal << 6) + (hashVal << 16) - hashVal;
  
  return hashVal;
}

static int sim_noise_equal(void* key1, void* key2) {
  return (strcmp((char*)key1, (char*)key2) == 0);
}

void generate_model(int mote) {
  uint64_t i;
  noise_model_t* noiseModel = &models[mote];
  noise_data_t* noiseData = &data[mote];
  noise_distribution_t* maxDist = NULL;
  // Not enough data to generate a model
  if (noiseData->size <= noiseModel->historyLength) {
    return;
  }
  free(noiseModel->firstReadings);
  noiseModel->firstReadings = (double*) malloc(sizeof(double) * noiseModel->historyLength);
  for (i = 0; i < noiseModel->historyLength; i++) {
    noiseModel->firstReadings[i] = noiseModel->lastReadings[i] = noiseData->readings[i];
  }

  for (;i < data[mote].size; i++) {
    double* dataStart = noiseData->readings + (i - noiseModel->historyLength);
    int dataLen = noiseModel->historyLength;
    int discretize = noiseModel->discretization;
    char* hashStr = generateHashString(dataStart, dataLen, discretize);
    int value = make_discrete(noiseData->readings[i], discretize);
    noise_distribution_t* dist = (noise_distribution_t*)hashtable_search(noiseModel->table, hashStr);
    if (dist == NULL) {
      dist = create_noise_distribution(mote);
      hashtable_insert(noiseModel->table, hashStr, dist);
    }
    add_val_to_distribution(dist, value);
    if (maxDist == NULL || dist->sum > maxDist->sum) {
      maxDist = dist;
    }
    //printf ("%llu: %s -> %i\n", i, hashStr, value);
  }
  noiseModel->common = maxDist;
  noiseModel->dirty = 0;
}

int main() {
  int i;
  char* hashStr;
  create_model(0, 1024, 10, 1, 10, 0);
  for (i = 0; i < 2000000; i++) {
    add_reading(0, (drand48() * 8.0));
  }
  generate_model(0);
  for (i = 0; i < 10000; i++) {
    double sample = getSample(0, sim_mote_start_time(0) +  i * sim_ticks_per_sec() / 1024);
    printf("%i: %f\n", i, sample);
  }
}

noise_distribution_t* create_noise_distribution(int mote) {
  noise_model_t* model = &models[mote];
  noise_distribution_t* dist = (noise_distribution_t*)malloc(sizeof(noise_distribution_t));
  dist->minValue = (int)model->minNoise;
  dist->numBuckets = model->bins;
  dist->sum = 0;
  dist->discretization = model->discretization;
  dist->counts = (int*)malloc(sizeof(int) * dist->numBuckets);
  memset(dist->counts, 0, sizeof(int) * dist->numBuckets);
  return dist;
}

void add_val_to_distribution(noise_distribution_t* dist, int value) {
  int index = value - dist->minValue;
  index /= dist->discretization;
  dist->counts[index]++;
  dist->sum++;
  //printf("Adding %i (%i:%i)\n", value, dist->sum, dist->counts[index]);
}
