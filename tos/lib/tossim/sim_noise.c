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


// $Id: sim_noise.c,v 1.1 2007-03-05 19:07:57 scipio Exp $


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

typedef struct noise_model {
  uint32_t historyLength;        // The history "k" of the model
  uint32_t sampleRateHz;         // The rate at which samples change
  hashtable_t* table;            // A pointer to the distribution hashtable
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
    int val = (int)readings[i];
    val /= discretization;
    val *= discretization;
    ptr += snprintf(ptr, SAMPLE_STR_LEN, "%i ", val);
  }
}

typedef struct noise_distribution {
  int dist;
} noise_distribution_t;


double sampleDistribution(noise_distribution_t* dist) {
  return 0;
}

void appendReading(int mote, double reading) {
  memcpy(models[mote].lastReadings, models[mote].lastReadings + 1, models[mote].historyLength - 1 * sizeof(double));
  models[mote].lastReadings[models[mote].historyLength - 1] = reading;
  models[mote].lastReading++;
}

void generateReading(int mote) {
  char* str = generateHashString(NULL, 0, 0);
  noise_distribution_t* noise = (noise_distribution_t*)hashtable_search(models[mote].table, hashString);
  double reading = sampleDistribution(noise);
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
  if (timePassed < 0) {
    return models[mote].lastReadings[0];
  }
  if (models[mote].dirty) {
    generate_model(mote);
  }
  readingNo = timePassed / (uint64_t)models[mote].increment;

  if (readingNo < models[mote].historyLength) {
    return models[mote].lastReadings[readingNo];
  }
  
  readingCount = readingNo - models[mote].lastReading;
  generateReadings(mote, readingCount);
  return models[mote].lastReadings[0];
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
    data[mote].size = 0;
    data[mote].maxSize = 0;
    if (data[mote].readings != NULL) {
      free(data[mote].readings);
      data[mote].readings = NULL;
    }
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

  // Not enough data to generate a model
  if (data[mote].size <= models[mote].historyLength) {
    return;
  }
  
  for (i = 0; i < models[mote].historyLength; i++) {
    models[mote].firstReadings[i] = data[mote].readings[i];
  }

  for (;i < data[mote].size; i++) {
    double* dataStart = data[mote].readings + (i - models[mote].historyLength);
    int dataLen = models[mote].historyLength;
    int discretize = models[mote].discretization;
    char* hashStr = generateHashString(dataStart, dataLen, discretize);
    printf ("%s\n", hashStr);
  }
}

int main() {
  int i;
  char* hashStr;
  create_model(0, 1024, 20, 4, 200, -120);
  for (i = 0; i < 200; i++) {
    models[0].lastReadings[i] = (drand48() * -60.0) - 40.0;
  }
  hashStr = generateHashString(models[0].lastReadings, 20, 3);
  printf ("%s\n", hashStr);  
}
