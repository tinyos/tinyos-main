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

generic module BlockingAMReceiverImplP() {
  provides {
    interface Init;
    interface BlockingReceive[uint8_t id];
    interface BlockingReceive as BlockingReceiveAny;
  }
  uses {
    interface Packet;
    interface Timer<TMilli>[uint8_t id];
    interface Receive[uint8_t id];
    interface SystemCall;
    interface SystemCallQueue;
    interface ThreadScheduler;
    interface Leds;
  }
}
implementation {
  
  typedef struct params {
    uint32_t*  timeout;
    message_t* msg;
    error_t    error;
  } params_t;

  //For parameterized BlockingReceive interface
  syscall_queue_t am_queue;
  
  //For single BlockingReceiveAny interface 
  bool blockForAny = FALSE;
  
  void timerTask(syscall_t* s) {
    params_t* p = s->params;
    call Timer.startOneShot[s->thread->id](*(p->timeout));  
  }
  
  command error_t Init.init() {
    call SystemCallQueue.init(&am_queue);
    blockForAny = FALSE;
    return SUCCESS;
  }
  
  void blockingReceive(syscall_t* s, am_id_t am_id, params_t* p, message_t* m, uint32_t* timeout) { 
    p->msg = m;
    p->timeout = timeout;
    atomic {
      p->error = EBUSY;
      if(*timeout != 0)
        call SystemCall.start(&timerTask, s, am_id, p);
      else
        call SystemCall.start(SYSCALL_WAIT_ON_EVENT, s, am_id, p);
    }
  }
  
  command error_t BlockingReceiveAny.receive(message_t* m, uint32_t timeout) {
    syscall_t s;
    params_t p;
    atomic {
      if((blockForAny == TRUE) || (call SystemCallQueue.isEmpty(&am_queue) == FALSE))
        return EBUSY;
      call SystemCallQueue.enqueue(&am_queue, &s);
      blockForAny = TRUE;
    }
    
    blockingReceive(&s, INVALID_ID, &p, m, &timeout);
    
    atomic {
      blockForAny = FALSE;
      call SystemCallQueue.remove(&am_queue, &s);
      return p.error;
    }
  }
  
  command error_t BlockingReceive.receive[uint8_t am_id](message_t* m, uint32_t timeout) {
    syscall_t s;
    params_t p;
    atomic {
      if((blockForAny == TRUE) || (call SystemCallQueue.find(&am_queue, am_id) != NULL))
        return EBUSY;
      call SystemCallQueue.enqueue(&am_queue, &s);
    }
	 
	blockingReceive(&s, am_id, &p, m, &timeout);
	
    atomic {
      call SystemCallQueue.remove(&am_queue, &s);
      return p.error;
    }	
  }

  command void* BlockingReceive.getPayload[uint8_t am_id](message_t* msg, uint8_t len) {
    return call Packet.getPayload(msg,len);
  }
  
  command void* BlockingReceiveAny.getPayload(message_t* msg, uint8_t len) {
    return call Packet.getPayload(msg,len);
  }
  
  event message_t* Receive.receive[uint8_t am_id](message_t* m, void* payload, uint8_t len) {
    syscall_t* s;
    params_t* p;
    
    if(blockForAny == TRUE)
      s = call SystemCallQueue.find(&am_queue, INVALID_ID);
    else
      s = call SystemCallQueue.find(&am_queue, am_id);
    if(s == NULL) return m;
        
    p = s->params;
    if( (p->error == EBUSY) ) {
      call Timer.stop[s->thread->id]();
      *(p->msg) = *m;
      p->error = SUCCESS;
      call SystemCall.finish(s);
    }
    return m;
  }
  
  event void Timer.fired[uint8_t id]() {
    thread_t* t = call ThreadScheduler.threadInfo(id);
    params_t* p = t->syscall->params;
    if( (p->error == EBUSY) ) {
      p->error = FAIL;
      call SystemCall.finish(t->syscall);
    }
  }
}
