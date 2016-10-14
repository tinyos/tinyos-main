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
 * - Neither the name of the copyright holder nor the names of
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
 * Implementation of TOSSIM C++ classes. Generally just directly
 * call their C analogues.
 *
 * @author Philip Levis
 * @author Chad Metcalf
 * @date   July 15 2007
 */

// $Id: tossim.c,v 1.2 2010-06-29 22:07:51 scipio Exp $


#include <stdint.h>
#include <tossim.h>
#include <sim_tossim.h>
#include <sim_mote.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <hashtable.h>

#include <mac.c>
#include <radio.c>
#include <packet.c>
#include <SerialPacket.c>
#include <sim_noise.h>

uint16_t TOS_NODE_ID = 1;

Variable::Variable(char* str, char* formatStr, int array, int which) {
  name = str;
  format = formatStr;
  isArray = array;
  mote = which;

  int sLen = strlen(name);
  realName = (char*)malloc(sLen + 1);
  memcpy(realName, name, sLen + 1);
  realName[sLen] = 0;

  for (int i = 0; i < sLen; i++) {
    if (realName[i] == '.') {
      realName[i] = '$';
    }
  }

  //  printf("Creating %s realName: %s format: %s %s\n", name, realName, formatStr, array? "[]":"");

  if (sim_mote_get_variable_info(mote, realName, &ptr, &len) == 0) {
    data = (char*)malloc(len + 1);
    data[len] = 0;
  }
  else {
    printf("Could not find variable %s\n", realName);
    data = NULL;
    ptr = NULL;
  }
  printf("Allocated variable %s\n", realName);
}

Variable::~Variable() {
  printf("Freeing variable %s\n", realName);
  free(data);
  free(realName);
}

/* This is the sdbm algorithm, taken from
   http://www.cs.yorku.ca/~oz/hash.html -pal */
static unsigned int tossim_hash(void* key) {
  char* str = (char*)key;
  unsigned int hashVal = 0;
  int c;

  while ((c = *str++))
    hashVal = c + (hashVal << 6) + (hashVal << 16) - hashVal;

  return hashVal;
}

static int tossim_hash_eq(void* key1, void* key2) {
  return strcmp((char*)key1, (char*)key2) == 0;
}


variable_string_t Variable::getData() {
  if (data != NULL && ptr != NULL) {
    str.ptr = data;
    str.type = format;
    str.len = len;
    str.isArray = isArray;
    //    printf("Getting %s %s %s\n", format, isArray? "[]":"", name);
    memcpy(data, ptr, len);
  }
  else {
    str.ptr = (char*)"<no such variable>";
    str.type = (char*)"<no such variable>";
    str.len = strlen("<no such variable>");
    str.isArray = 0;
  }
  return str;
}

Mote::Mote(nesc_app_t* n) {
  app = n;
  varTable = create_hashtable(128, tossim_hash, tossim_hash_eq);
}

Mote::~Mote(){}

unsigned long Mote::id() {
  return nodeID;
}

long long int Mote::euid() {
  return sim_mote_euid(nodeID);
}

void Mote::setEuid(long long int val) {
  sim_mote_set_euid(nodeID, val);
}

long long int Mote::bootTime() {
  return sim_mote_start_time(nodeID);
}

void Mote::bootAtTime(long long int time) {
  sim_mote_set_start_time(nodeID, time);
  sim_mote_enqueue_boot_event(nodeID);
}

bool Mote::isOn() {
  return sim_mote_is_on(nodeID);
}

void Mote::turnOff() {
  sim_mote_turn_off(nodeID);
}

void Mote::turnOn() {
  sim_mote_turn_on(nodeID);
}

void Mote::setID(unsigned long val) {
  nodeID = val;
}

Variable* Mote::getVariable(char* name) {
  char* typeStr = (char*)"";
  int isArray;
  Variable* var;

  var = (Variable*)hashtable_search(varTable, name);
  if (var == NULL) {
    // Could hash this for greater efficiency,
    // but that would either require transformation
    // in Tossim class or a more complex typemap.
    if (app != NULL) {
      for (int i = 0; i < app->numVariables; i++) {
	if(strcmp(name, app->variableNames[i]) == 0) {
	  typeStr = app->variableTypes[i];
	  isArray = app->variableArray[i];
	  break;
	}
      }
    }
    //  printf("Getting variable %s of type %s %s\n", name, typeStr, isArray? "[]" : "");
    var = new Variable(name, typeStr, isArray, nodeID);
    hashtable_insert(varTable, name, var);
  }
  return var;
}

void Mote::addNoiseTraceReading(int val) {
  sim_noise_trace_add(id(), (char)val);
}

void Mote::createNoiseModel() {
  sim_noise_create_model(id());
}

int Mote::generateNoise(int when) {
  return (int)sim_noise_generate(id(), sim_mote_get_radio_channel(id()), when);
}

Tossim::Tossim(nesc_app_t* n) {
  app = n;
  init();
}

Tossim::~Tossim() {
  sim_end();
}

void Tossim::init() {
  sim_init();
  motes = (Mote**)malloc(sizeof(Mote*) * (TOSSIM_MAX_NODES + 1));
  memset(motes, 0, sizeof(Mote*) * TOSSIM_MAX_NODES);
}

long long int Tossim::time() {
  return sim_time();
}

long long int Tossim::ticksPerSecond() {
  return sim_ticks_per_sec();
}

char* Tossim::timeStr() {
  sim_print_now(timeBuf, 256);
  return timeBuf;
}

void Tossim::setTime(long long int val) {
  sim_set_time(val);
}

Mote* Tossim::currentNode() {
  return getNode(sim_node());
}

Mote* Tossim::getNode(unsigned long nodeID) {
  if (nodeID > TOSSIM_MAX_NODES) {
    nodeID = TOSSIM_MAX_NODES;
    // log an error, asked for an invalid node
  }
  else {
    if (motes[nodeID] == NULL) {
      motes[nodeID] = new Mote(app);
      if (nodeID == TOSSIM_MAX_NODES) {
	motes[nodeID]->setID(0xffff);
      }
      else {
	motes[nodeID]->setID(nodeID);
      }
    }
    return motes[nodeID];
  }
}

void Tossim::setCurrentNode(unsigned long nodeID) {
  sim_set_node(nodeID);
}

void Tossim::addChannel(char* channel, FILE* file) {
  sim_add_channel(channel, file);
}

bool Tossim::removeChannel(char* channel, FILE* file) {
  return sim_remove_channel(channel, file);
}

void Tossim::randomSeed(int seed) {
  return sim_random_seed(seed);
}

bool Tossim::runNextEvent() {
  return sim_run_next_event();
}

MAC* Tossim::mac() {
  return new MAC();
}

Radio* Tossim::radio() {
  return new Radio();
}

Packet* Tossim::newPacket() {
  return new Packet();
}

SerialPacket* Tossim::newSerialPacket() {
  return new SerialPacket();
}
