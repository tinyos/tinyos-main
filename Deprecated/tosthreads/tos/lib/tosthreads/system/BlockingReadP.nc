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

generic module BlockingReadP() {
  provides {
    interface Init;
    interface BlockingRead<uint16_t> as BlockingRead[uint8_t client];
  }
  uses {
    interface Read<uint16_t> as Read[uint8_t client];
    
    interface SystemCall;
    interface SystemCallQueue;
  }
}
implementation {

  typedef struct read_params {
    uint16_t* val;
    error_t   error;
  } read_params_t;

  syscall_queue_t read_queue;
  
  command error_t Init.init() {
    call SystemCallQueue.init(&read_queue);
    return SUCCESS;
  }
  
  /**************************** Read ********************************/
  void readTask(syscall_t* s) {
    read_params_t* p = s->params;
    p->error = call Read.read[s->id]();
    if(p->error != SUCCESS) {
      call SystemCall.finish(s);
    } 
  }  
  
  command error_t BlockingRead.read[uint8_t id](uint16_t* val) {
    syscall_t s;
    read_params_t p;
    atomic {
      if(call SystemCallQueue.find(&read_queue, id) != NULL)
        return EBUSY;
      call SystemCallQueue.enqueue(&read_queue, &s);
    }
    
    p.val = val;
    call SystemCall.start(&readTask, &s, id, &p);
    
    atomic {
      call SystemCallQueue.remove(&read_queue, &s);
      return p.error;
    }
  }
  
  event void Read.readDone[uint8_t id]( error_t result, uint16_t val ) {
    syscall_t* s = call SystemCallQueue.find(&read_queue, id);
    read_params_t* p = s->params;
    *(p->val) = val;
    p->error = result;
    call SystemCall.finish(s);  
  }
  default command error_t Read.read[uint8_t id]() { return FAIL; }

}
