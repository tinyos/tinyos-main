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
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

#include <SensirionSht11.h>

generic module BlockingSensirionSht11ReaderImplP() {
  provides {
    interface BlockingRead<uint16_t> as BlockingTemperature;
    interface BlockingRead<uint16_t> as BlockingHumidity;
  }
  uses {
    interface Read<uint16_t> as Temperature;
    interface Read<uint16_t> as Humidity;
    
    interface SystemCall;
  }
}
implementation {
  typedef struct params {
    uint16_t* val;
    error_t   error;
  } params_t;

  syscall_t* temp_call = NULL;
  syscall_t* hum_call = NULL;
  
  void tempTask(syscall_t* s) {
    params_t* p = s->params;
    p->error = call Temperature.read();
    if(p->error != SUCCESS) {
      call SystemCall.finish(s);
    }  
  }
  
  void humTask(syscall_t* s) {
    params_t* p = s->params;
    p->error = call Humidity.read();
    if(p->error != SUCCESS) {
      call SystemCall.finish(s);
    }  
  }
  
  error_t blockingRead(syscall_t** s_call, uint16_t* val, void* task_ptr) {
    syscall_t s;
    params_t p;
    atomic {
      if(*s_call != NULL)
        return EBUSY;
      *s_call = &s;
    }
    
    p.val = val;
    call SystemCall.start(task_ptr, &s, INVALID_ID, &p);
    
    atomic {
      *s_call = NULL;
      return p.error;
    }    
  }

  command error_t BlockingTemperature.read(uint16_t* val) {
    return blockingRead(&temp_call, val, tempTask);
  }
  
  command error_t BlockingHumidity.read(uint16_t* val) {
    return blockingRead(&hum_call, val, humTask);
  }

  event void Temperature.readDone( error_t result, uint16_t val ) {
    params_t* p = temp_call->params;
    p->error = result;
    *(p->val) = val;
    call SystemCall.finish(temp_call);
  }  
  
  event void Humidity.readDone( error_t result, uint16_t val ) {
    params_t* p = hum_call->params;
    p->error = result;
    *(p->val) = val;
    call SystemCall.finish(hum_call);
  }
}
