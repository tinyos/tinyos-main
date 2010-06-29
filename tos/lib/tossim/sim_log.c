// $Id: sim_log.c,v 1.7 2010-06-29 22:07:51 scipio Exp $

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
 * The TOSSIM logging system.
 *
 * @author Phil Levis
 * @date   November 9 2005
 */

#include <sim_log.h>
#include <stdio.h>
#include <stdarg.h>
#include <hashtable.h>
#include <string.h>

enum {
  DEFAULT_CHANNEL_SIZE = 8
};

typedef struct sim_log_output {
  int num;
  FILE** files;
} sim_log_output_t;

typedef struct sim_log_channel {
  const char* name;
  int numOutputs;
  int size;
  FILE** outputs;
} sim_log_channel_t;

enum {
  SIM_LOG_OUTPUT_COUNT = uniqueCount("TOSSIM.debug")
};

sim_log_output_t outputs[SIM_LOG_OUTPUT_COUNT];
struct hashtable* channelTable = NULL;


static unsigned int sim_log_hash(void* key);
static int sim_log_eq(void* key1, void* key2);


// First we count how many outputs there are,
// then allocate a FILE** large enough and fill it in.
// This FILE** might be larger than needed, because
// the outputs of the channels might have redundancies.
// E.g., if two channels A and B are both to stdout, then
// you don't want a channel of "A,B" to be doubly printed
// to stdout. So when the channel's FILE*s are copied
// into the debug point output array, this checks
// for redundancies by checking file descriptors.
static void fillInOutput(int id, char* name) {
  char* termination = name;
  char* namePos = name;
  int count = 0;
  char* newName = (char*)malloc(strlen(name) + 1);
  memset(newName, 0, strlen(name) + 1);
  // Count the outputs
  while (termination != NULL) {
    sim_log_channel_t* channel;
    
    termination = strrchr(namePos, ',');
    // If we've reached the end, just copy to the end
    if (termination == NULL) {
      strcpy(newName, namePos);
    }
    // Otherwise, memcpy over and null terminate
    else {
      memcpy(newName, namePos, (termination - namePos));
      newName[termination - namePos] = 0;
    }
    
    channel = hashtable_search(channelTable, namePos);
    if (channel != NULL) {
      count += channel->numOutputs;
    }

    namePos = termination + 1;
  }

  termination = name;
  namePos = name;
  
  // Allocate
  outputs[id].files = (FILE**)malloc(sizeof(FILE*) * count);
  outputs[id].num = 0;

  // Fill it in
  while (termination != NULL) {
    sim_log_channel_t* channel;
    
    termination = strrchr(namePos, ',');
    // If we've reached the end, just copy to the end
    if (termination == NULL) {
      strcpy(newName, namePos);
    }
    // Otherwise, memcpy over and null terminate
    else {
      memcpy(newName, namePos, (termination - namePos));
      newName[termination - namePos] = 0;
    }
    
    channel = hashtable_search(channelTable, namePos);
    if (channel != NULL) {
      int i, j;
      for (i = 0; i < channel->numOutputs; i++) {
	int duplicate = 0;
	int outputCount = outputs[id].num;
	// Check if we already have this file descriptor in the output
	// set, and if so, ignore it.
	for (j = 0; j < outputCount; j++) {
	  if (fileno(outputs[id].files[j]) == fileno(channel->outputs[i])) {
	    duplicate = 1;
	    j = outputCount;
	  }
	}
	if (!duplicate) {
	  outputs[id].files[outputCount] = channel->outputs[i];
	  outputs[id].num++;
	}
      }
    }
    namePos = termination + 1;
  }
}

void sim_log_init() {
  int i;

  channelTable = create_hashtable(128, sim_log_hash, sim_log_eq);
  
  for (i = 0; i < SIM_LOG_OUTPUT_COUNT; i++) {
    outputs[i].num = 1;
    outputs[i].files = (FILE**)malloc(sizeof(FILE*));
    outputs[i].files[0] = fdopen(1, "w"); // STDOUT
  }
  
}

void sim_log_add_channel(char* name, FILE* file) {
  sim_log_channel_t* channel;
  channel = (sim_log_channel_t*)hashtable_search(channelTable, name);
  
  // If there's no current entry, allocate one, initialize it,
  // and insert it.
  if (channel == NULL) {
    char* newName = (char*)malloc(strlen(name) + 1);
    strcpy(newName, name);
    newName[strlen(name)] = 0;
    
    channel = (sim_log_channel_t*)malloc(sizeof(sim_log_channel_t));
    channel->name = newName;
    channel->numOutputs = 0;
    channel->size = DEFAULT_CHANNEL_SIZE;
    channel->outputs = (FILE**)malloc(sizeof(FILE*) * channel->size);
    memset(channel->outputs, 0, sizeof(FILE*) * channel->size);
    hashtable_insert(channelTable, newName, channel);
  }

  // If the channel output table is full, double the size of
  // channel->outputs.
  if (channel->numOutputs == channel->size) {
    FILE** newOutputs;
    int newSize = channel->size * 2;
    
    newOutputs = (FILE**)malloc(sizeof(FILE*) * newSize);
    memcpy(newOutputs, channel->outputs, channel->size * sizeof(FILE**));

    free(channel->outputs);

    channel->outputs = newOutputs;
    channel->size    = newSize;
  }

  channel->outputs[channel->numOutputs] = file;
  channel->numOutputs++;
  sim_log_commit_change();
}

bool sim_log_remove_channel(char* output, FILE* file) {
  sim_log_channel_t* channel;
  int i;
  channel = (sim_log_channel_t*)hashtable_search(channelTable, output);  

  if (channel == NULL) {
    return FALSE;
  }

  // Note: if a FILE* has duplicates, this removes all of them
  for (i = 0; i < channel->numOutputs; i++) {
    FILE* f = channel->outputs[i];
    if (file == f) {
      memcpy(&channel->outputs[i], &channel->outputs[i + 1], (channel->numOutputs) - (i + 1));
      channel->outputs[channel->numOutputs - 1] = NULL;
      channel->numOutputs--;
    }
  }
  
  return TRUE;
}
  
void sim_log_commit_change() {
  int i;
  for (i = 0; i < SIM_LOG_OUTPUT_COUNT; i++) {
    if (outputs[i].files != NULL) {
      outputs[i].num = 0;
      free(outputs[i].files);
      outputs[i].files = NULL;
    }
  }
}


void sim_log_debug(uint16_t id, char* string, const char* format, ...) {
  va_list args;
  int i;
  if (outputs[id].files == NULL) {
    fillInOutput(id, string);
  }
  for (i = 0; i < outputs[id].num; i++) {
    FILE* file = outputs[id].files[i];
    va_start(args, format);
    fprintf(file, "DEBUG (%i): ", (int)sim_node());
    vfprintf(file, format, args); 
    fflush(file);
  }
}

void sim_log_error(uint16_t id, char* string, const char* format, ...) {
  va_list args;
  int i;
  if (outputs[id].files == NULL) {
    fillInOutput(id, string);
  }
  for (i = 0; i < outputs[id].num; i++) {
    FILE* file = outputs[id].files[i];
    va_start(args, format);
    fprintf(file, "ERROR (%i): ", (int)sim_node());
    vfprintf(file, format, args);
    fflush(file);
  }
}

void sim_log_debug_clear(uint16_t id, char* string, const char* format, ...) {
  va_list args;
  int i;
  if (outputs[id].files == NULL) {
    fillInOutput(id, string);
  }
  for (i = 0; i < outputs[id].num; i++) {
    FILE* file = outputs[id].files[i];
    va_start(args, format);
    vfprintf(file, format, args);
    fflush(file);
  }
}

void sim_log_error_clear(uint16_t id, char* string, const char* format, ...) {
  va_list args;
  int i;
  if (outputs[id].files == NULL) {
    fillInOutput(id, string);
  }
  for (i = 0; i < outputs[id].num; i++) {
    FILE* file = outputs[id].files[i];
    va_start(args, format);
    vfprintf(file, format, args);
    fflush(file);
  }
}

/* This is the sdbm algorithm, taken from
   http://www.cs.yorku.ca/~oz/hash.html -pal */
static unsigned int sim_log_hash(void* key) {
  char* str = (char*)key;
  unsigned int hashVal = 0;
  int hashChar;
  
  while ((hashChar = *str++))
    hashVal = hashChar + (hashVal << 6) + (hashVal << 16) - hashVal;
  
  return hashVal;
}

static int sim_log_eq(void* key1, void* key2) {
  return strcmp((char*)key1, (char*)key2) == 0;
}
