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
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

generic module BlockingAMSenderImplP() {
  provides {
    interface Init;
    interface BlockingAMSend[am_id_t id];
  }
  uses {
    interface SystemCall;
    interface Mutex;
    interface AMSend[am_id_t id];
    interface Packet;
    interface Leds;
  }
}
implementation {

  typedef struct params {
    am_addr_t  addr;
    message_t* msg;
    uint8_t    len;
    error_t    error;
  } params_t;
  
  syscall_t* send_call = NULL;
  mutex_t my_mutex;
  
  void sendTask(syscall_t* s) {
    params_t* p = s->params;
    p->error = call AMSend.send[s->id](p->addr, p->msg, p->len);
    if(p->error != SUCCESS)
      call SystemCall.finish(s);
  }
  
  command error_t Init.init() {
    call Mutex.init(&my_mutex);
    return SUCCESS;
  }
  
  command error_t BlockingAMSend.send[am_id_t am_id](am_addr_t addr, message_t* msg, uint8_t len) {
    syscall_t s;
    params_t p;
    call Mutex.lock(&my_mutex);
      if (send_call == NULL) {
        send_call = &s;
      
        p.addr = addr;
        p.msg = msg;
        p.len = len;
      
        call SystemCall.start(&sendTask, &s, am_id, &p);
        send_call = NULL;
      } else {
        p.error = EBUSY;
      }
    
    atomic {
      call Mutex.unlock(&my_mutex);
      return p.error;
    }
  }

  command uint8_t BlockingAMSend.maxPayloadLength[am_id_t id]() {
    return call Packet.maxPayloadLength();
  }
  command void* BlockingAMSend.getPayload[am_id_t id](message_t* msg, uint8_t len) {
    return call Packet.getPayload(msg, len);
  }
  
  event void AMSend.sendDone[am_id_t am_id](message_t* m, error_t error) {
    if (send_call != NULL) {
      if (send_call->id == am_id) {
        params_t* p;
        p = send_call->params;
        p->error = error;
        call SystemCall.finish(send_call);
      }
    }
  }
  default command error_t AMSend.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len) {
    return FAIL;
  }
}















