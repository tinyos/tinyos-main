/*
 * Copyright (c) 2008 Johns Hopkins University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the (updated) modification history and the author appear in
 * all copies of this source code.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
 * OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

#include "message.h"

module BlockingSendImplP {
  provides {
    interface Init;
    interface BlockingSend[uint8_t id];
  }
  uses {
    interface Send[uint8_t id];
    interface SystemCall;
    interface SystemCallQueue;
  }
}

implementation {

  typedef struct params {
    message_t* msg;
    uint8_t len;
    error_t error;
  } params_t;

  syscall_queue_t send_queue;
 
  command error_t Init.init() {
    call SystemCallQueue.init(&send_queue);
    return SUCCESS;
  }
  
  void sendTask(syscall_t* s) {
    params_t* p = s->params;
    p->error = call Send.send[s->id](p->msg, p->len);
    if(p->error != SUCCESS)
      call SystemCall.finish(s);
  }  
  
  command error_t BlockingSend.send[uint8_t id](message_t* msg, uint8_t len) {
    syscall_t s;
    params_t p;
    atomic {
      if(call SystemCallQueue.find(&send_queue, id) != NULL)
        return EBUSY;
      call SystemCallQueue.enqueue(&send_queue, &s);
    }
    
    p.msg = msg;
    p.len = len;
    call SystemCall.start(&sendTask, &s, id, &p);
    
    atomic {
      call SystemCallQueue.remove(&send_queue, &s);
      return p.error;
    }
  }
  
  event void Send.sendDone[uint8_t id](message_t* msg, error_t error) {
    syscall_t* s = call SystemCallQueue.find(&send_queue, id);
    params_t* p = s->params;    
    p->error = error;
    call SystemCall.finish(s);
  }
  
  command uint8_t BlockingSend.maxPayloadLength[uint8_t id]() {
    return call Send.maxPayloadLength[id]();
  }
  
  command void* BlockingSend.getPayload[uint8_t id](message_t* msg, uint8_t len) {
    return call Send.getPayload[id](msg, len);
  }
  
  default command error_t Send.send[uint8_t id](message_t* msg, uint8_t len) { return FAIL; }
  default command uint8_t Send.maxPayloadLength[uint8_t id]() { return 0; }
  default command void* Send.getPayload[uint8_t id](message_t* msg, uint8_t len) { return NULL; }
}
