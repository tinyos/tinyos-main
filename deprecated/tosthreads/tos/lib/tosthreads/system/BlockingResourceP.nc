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

generic module BlockingResourceP() {
  provides {
    interface BlockingResource;
  }
  uses {
    interface SystemCall;
    interface ThreadScheduler;
    interface Resource;
    interface ThreadSleep;
  }
}
implementation {
  typedef struct params {
    error_t   error;
  } params_t;
  
  syscall_t* resource_call = NULL;
  
  /**************************** Request ********************************/
  void requestTask(syscall_t* s) {
    params_t* p = s->params;
    p->error = call Resource.request();
    if(p->error != SUCCESS)
      call SystemCall.finish(s);
  }  
  
  command error_t BlockingResource.request() {
    syscall_t s;
    params_t p;
    atomic {
      if(resource_call != NULL)
        return EBUSY;
      resource_call = &s;
    }
    
    call SystemCall.start(requestTask, &s, INVALID_ID, &p);
    
    atomic {
      resource_call = NULL;
      return p.error;
    }  
  }
  
  event void Resource.granted() {
    params_t* p = resource_call->params;
    p->error = SUCCESS;
    call SystemCall.finish(resource_call);
  }
  
  /**************************** Release ********************************/
  void releaseTask(syscall_t* s) {
    params_t* p = s->params;
    p->error = call Resource.release();
    call SystemCall.finish(s);
  }  
  
  command error_t BlockingResource.release() {
    syscall_t s;
    params_t p;
    atomic {
      if(resource_call != NULL)
        return EBUSY;
      resource_call = &s;
    }
    
    call SystemCall.start(releaseTask, &s, INVALID_ID, &p);
    
    atomic {
      resource_call = NULL;
      return p.error;
    }  
  }
  
  /************************* Timed Release *****************************/
  command error_t BlockingResource.timedRelease(uint32_t milli) {
    syscall_t s;
    params_t p;
    atomic {
      if(resource_call != NULL)
        return EBUSY;
      resource_call = &s;
    }
    
    if(milli != 0)
      call ThreadSleep.sleep(milli);

    call SystemCall.start(releaseTask, &s, INVALID_ID, &p); 
    if(p.error == SUCCESS)
      call SystemCall.start(requestTask, &s, INVALID_ID, &p); 
    
    atomic {
      resource_call = NULL;
      return p.error;
    }  
  }
  
  /************************* isOwner pass through *****************************/
  command bool BlockingResource.isOwner() {
    return call Resource.isOwner();
  }
}















