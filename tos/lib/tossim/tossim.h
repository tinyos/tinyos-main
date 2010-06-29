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
 * Declaration of C++ objects representing TOSSIM abstractions.
 * Used to generate Python objects.
 *
 * @author Philip Levis
 * @date   Nov 22 2005
 */

// $Id: tossim.h,v 1.6 2010-06-29 22:07:51 scipio Exp $

#ifndef TOSSIM_H_INCLUDED
#define TOSSIM_H_INCLUDED

//#include <stdint.h>
#include <memory.h>
#include <tos.h>
#include <mac.h>
#include <radio.h>
#include <packet.h>
#include <hashtable.h>

typedef struct variable_string {
  char* type;
  char* ptr;
  int len;
  int isArray;
} variable_string_t;

typedef struct nesc_app {
  int numVariables;
  char** variableNames;
  char** variableTypes;
  int* variableArray;
} nesc_app_t;

class Variable {
 public:
  Variable(char* name, char* format, int array, int mote);
  ~Variable();
  variable_string_t getData();
  
 private:
  char* name;
  char* realName;
  char* format;
  int mote;
  void* ptr;
  char* data;
  size_t len;
  int isArray;
  variable_string_t str;
};

class Mote {
 public:
  Mote(nesc_app_t* app);
  ~Mote();

  unsigned long id();
  
  long long int euid();
  void setEuid(long long int id);

  long long int bootTime();
  void bootAtTime(long long int time);

  bool isOn();
  void turnOff();
  void turnOn();
  void setID(unsigned long id);  

  void addNoiseTraceReading(int val);
  void createNoiseModel();
  int generateNoise(int when);
  
  Variable* getVariable(char* name);
  
 private:
  unsigned long nodeID;
  nesc_app_t* app;
  struct hashtable* varTable;
};

class Tossim {
 public:
  Tossim(nesc_app_t* app);
  ~Tossim();
  
  void init();
  
  long long int time();
  long long int ticksPerSecond();
  char* timeStr();
  void setTime(long long int time);
  
  Mote* currentNode();
  Mote* getNode(unsigned long nodeID);
  void setCurrentNode(unsigned long nodeID);

  void addChannel(char* channel, FILE* file);
  bool removeChannel(char* channel, FILE* file);
  void randomSeed(int seed);
  
  bool runNextEvent();

  MAC* mac();
  Radio* radio();
  Packet* newPacket();

 private:
  char timeBuf[256];
  nesc_app_t* app;
  Mote** motes;
};



#endif // TOSSIM_H_INCLUDED
