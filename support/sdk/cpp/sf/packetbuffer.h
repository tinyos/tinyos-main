/*
 * Copyright (c) 2007, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
 * @author Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 */

#ifndef PACKETBUFFER_H
#define PACKETBUFFER_H

#include <pthread.h>
#include <list>
#include "sfpacket.h"

//#define DEBUG_PACKETBUFFER

#undef DEBUG
#ifdef DEBUG_PACKETBUFFER
#include <iostream>
#define DEBUG(message) std::cout << message << std::endl;
#else
#define DEBUG(message) 
#endif

class PacketBuffer
{
protected:

  static const int cMaxBufferSize = 25;

  typedef std::list<SFPacket> container_t;

  // thread safe buffer
  typedef struct
  {
    // mutex lock for any of this vars
    pthread_mutex_t lock;
    // notempty cond
    pthread_cond_t notempty;
    // not full cond
    pthread_cond_t notfull;
    // actual buffer 
    container_t container;
    // number of packets in buffer
    int size;
  } sharedBuffer_t;

  sharedBuffer_t buffer;

public:
  PacketBuffer();

  ~PacketBuffer();

  void clear();

  SFPacket dequeue();

  bool enqueueFront(SFPacket &pPacket);

  bool enqueueBack(SFPacket &pPacket);

  bool isFull();

  bool isEmpty();

  bool isInQueue(SFPacket &pPacket);
  
};

#endif
