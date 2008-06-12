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

module BlockingStdControlImplP {
  provides {
    interface Init;
    interface BlockingStdControl[uint8_t id];
  }
  uses {
    interface SplitControl[uint8_t id];
    interface SystemCall;
    interface SystemCallQueue;
    interface Leds;
  }
}

implementation {

  typedef struct params {
    error_t error;
  } params_t;

  syscall_queue_t std_cntrl_queue;
 
  command error_t Init.init() {
    call SystemCallQueue.init(&std_cntrl_queue);
    return SUCCESS;
  }
  
  /**************************** Start ********************************/
  void startTask(syscall_t* s) {
    params_t* p = s->params;
    p->error = call SplitControl.start[s->id]();
    if(p->error != SUCCESS)
      call SystemCall.finish(s);
  }  
  
  command error_t BlockingStdControl.start[uint8_t id]() {
    syscall_t s;
    params_t p;
    atomic {
      if(call SystemCallQueue.find(&std_cntrl_queue, id) != NULL)
        return EBUSY;
      call SystemCallQueue.enqueue(&std_cntrl_queue, &s);
    }
    
    call SystemCall.start(&startTask, &s, id, &p);
    
    atomic {
      call SystemCallQueue.remove(&std_cntrl_queue, &s);
      return p.error;
    }
  }
  
  event void SplitControl.startDone[uint8_t id](error_t error) {
    syscall_t* s = call SystemCallQueue.find(&std_cntrl_queue, id);
    params_t* p = s->params;    
    p->error = error;
    call SystemCall.finish(s);
  }
  
  /**************************** Stop ********************************/
  void stopTask(syscall_t* s) {
    params_t* p = s->params;
    p->error = call SplitControl.stop[s->id]();
    if(p->error != SUCCESS)
      call SystemCall.finish(s);
  }
  
  command error_t BlockingStdControl.stop[uint8_t id]() {
    syscall_t s;
    params_t p;
    atomic {
      if(call SystemCallQueue.find(&std_cntrl_queue, id) != NULL)
        return EBUSY;
      call SystemCallQueue.enqueue(&std_cntrl_queue, &s);
    }
    
    call SystemCall.start(&stopTask, &s, id, &p);
    
    atomic {
      call SystemCallQueue.remove(&std_cntrl_queue, &s);
      return p.error;
    }
  }
  
  event void SplitControl.stopDone[uint8_t id](error_t error) {
    syscall_t* s = call SystemCallQueue.find(&std_cntrl_queue, id);
    params_t* p = s->params;
    p->error = error;
    call SystemCall.finish(s);
  }
  default command error_t SplitControl.start[uint8_t id]() { return SUCCESS; }
  default command error_t SplitControl.stop[uint8_t id]() { return SUCCESS; }
}















