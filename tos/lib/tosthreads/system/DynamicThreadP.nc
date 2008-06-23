/*
 * Copyright (c) 2008 Stanford University.
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
 * @author Kevin Klues (klueska@cs.stanford.edu)
 */
 
#include "thread.h"

module DynamicThreadP {
  provides {
    interface DynamicThread;
    interface ThreadInfo[uint8_t];
    interface ThreadNotification[uint8_t];
  }
  uses {
    interface ThreadCleanup[uint8_t];
    interface ThreadScheduler;
    interface ThreadSleep;
    interface BitArrayUtils;
    interface Malloc;
    interface Leds;
  }
}
implementation {
  thread_t* thread_info[TOSTHREAD_MAX_DYNAMIC_THREADS];
  uint8_t* stack_heads[TOSTHREAD_MAX_DYNAMIC_THREADS];
  uint8_t thread_map[((TOSTHREAD_MAX_DYNAMIC_THREADS - 1) / 8 + 1)];
  thread_id_t last_id_given = -1;
  
  enum {
    THREAD_OVERFLOW = TOSTHREAD_MAX_DYNAMIC_THREADS,
  };
  
  thread_id_t getNextId() {
    thread_id_t i;
    for(i=last_id_given+1; i<TOSTHREAD_MAX_DYNAMIC_THREADS; i++) {
      if(call BitArrayUtils.getBit(thread_map, i) == 0)
        goto happy;
    }
    for(i=0; i<last_id_given; i++) {
      if(call BitArrayUtils.getBit(thread_map, i) == 0)
        goto happy; 
    }
    return THREAD_OVERFLOW;
happy: 
    last_id_given = i;
    return i;
  }
  
  error_t init(tosthread_t* t, void (*start_routine)(void*), void* arg, uint16_t stack_size) {
    void* temp;
    *t = getNextId();
    if(*t != THREAD_OVERFLOW) {
      if((temp = call Malloc.malloc(sizeof(thread_t) + stack_size)) != NULL) {
        thread_info[*t] = temp;
        stack_heads[*t] = &(((uint8_t*)temp)[sizeof(thread_t)]);
      }
      else return FAIL;
      call BitArrayUtils.setBit(thread_map, *t);
      thread_info[*t]->next_thread = NULL; 
      thread_info[*t]->id = *t + TOSTHREAD_NUM_STATIC_THREADS;
      thread_info[*t]->init_block = NULL;
      thread_info[*t]->stack_ptr = (stack_ptr_t)(STACK_TOP(stack_heads[*t], stack_size));
      thread_info[*t]->state = TOSTHREAD_STATE_INACTIVE;
      thread_info[*t]->mutex_count = 0;
      thread_info[*t]->start_ptr = start_routine;
      thread_info[*t]->start_arg_ptr = arg;
      thread_info[*t]->syscall = NULL;
      memset(&(thread_info[*t]->regs), 0, sizeof(thread_regs_t));
      *t += TOSTHREAD_NUM_STATIC_THREADS;
      return call ThreadScheduler.initThread(*t);
    }
    return FAIL;
  }

  command error_t DynamicThread.create(tosthread_t* t, void (*start_routine)(void*), void* arg, uint16_t stack_size) {
   atomic {
     if(init(t, start_routine, arg, stack_size) == SUCCESS ) {
        error_t e = call ThreadScheduler.startThread(*t);
        if(e == SUCCESS)
         signal ThreadNotification.justCreated[*t]();
        return e;
      }
    }
    return FAIL;
  }
  command error_t DynamicThread.destroy(tosthread_t* t) {
    atomic {
      if(call ThreadScheduler.stopThread(*t) == SUCCESS) {
         signal ThreadCleanup.cleanup[*t]();
         return SUCCESS;
      }
    }
    return FAIL;
  }
  command error_t DynamicThread.pause(tosthread_t* t) {
    if(call BitArrayUtils.getBit(thread_map, *t-TOSTHREAD_NUM_STATIC_THREADS) == TRUE) {
      return call ThreadScheduler.stopThread(*t);
    }
    return FAIL;
  }
  command error_t DynamicThread.resume(tosthread_t* t) {
    if(call BitArrayUtils.getBit(thread_map, *t-TOSTHREAD_NUM_STATIC_THREADS) == TRUE) {
      return call ThreadScheduler.startThread(*t);
    }
    return FAIL;  
  }
  command error_t DynamicThread.sleep(uint32_t milli) {
    return call ThreadSleep.sleep(milli);
  }
  
  async command thread_t* ThreadInfo.get[uint8_t id]() {
    atomic return thread_info[id - TOSTHREAD_NUM_STATIC_THREADS];
  }
  
  async event void ThreadCleanup.cleanup[uint8_t id]() {
    call Leds.led2Toggle();
    signal ThreadNotification.aboutToDestroy[id]();
    atomic {
      uint8_t adjusted_id = id-TOSTHREAD_NUM_STATIC_THREADS;
      call Malloc.free(thread_info[adjusted_id]);
      call BitArrayUtils.clrBit(thread_map, adjusted_id);
    }
  }
  default async event void ThreadNotification.justCreated[uint8_t id]() {}
  default async event void ThreadNotification.aboutToDestroy[uint8_t id]() {}
}
