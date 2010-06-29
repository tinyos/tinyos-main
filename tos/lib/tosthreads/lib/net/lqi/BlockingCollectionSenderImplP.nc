/*
 * Copyright (c) 2008 Johns Hopkins University.
 * All rights reserved.
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
 * - Neither the name of the copyright holders nor the names of
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

/*
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */
 
module BlockingCollectionSenderImplP {
  provides {
    interface BlockingSend[uint8_t client];
    interface Init;
  }
  
  uses {
    interface Send[uint8_t client];
    interface SystemCall;
    interface Mutex;
    interface Packet;
    interface Leds;
    interface CollectionPacket;
    interface CollectionId[uint8_t client];
  }
}

implementation {
  typedef struct params {
    message_t *msg;
    uint8_t len;
    error_t error;
  } params_t;
  
  syscall_t* send_call;
  mutex_t my_mutex;
  
  command error_t Init.init()
  {
    call Mutex.init(&my_mutex);
    return SUCCESS;
  }

  void sendTask(syscall_t *s)
  {
    params_t* p = s->params;
    
    call CollectionPacket.setType(p->msg, call CollectionId.fetch[s->id]());
    p->error = call Send.send[s->id](p->msg, p->len);
    if(p->error != SUCCESS) {
      call SystemCall.finish(s);
    }
  }

  command error_t BlockingSend.send[uint8_t client](message_t *msg, uint8_t len)
  {
    syscall_t s;
    params_t p;
    call Mutex.lock(&my_mutex);
    send_call = &s;
    
    p.msg = msg;
    p.len = len;
    
    call SystemCall.start(&sendTask, &s, client, &p);
    
    atomic {
      call Mutex.unlock(&my_mutex);
      return p.error;
    }
  }
  
  event void Send.sendDone[uint8_t client](message_t* m, error_t error)
  {
    if (client == send_call->id) {
      params_t* p;
      
      p = send_call->params;
      p->error = error;
      call SystemCall.finish(send_call);
    }
  }
  
  command error_t BlockingSend.cancel[uint8_t client](message_t* msg)
  {
    return call Send.cancel[client](msg);
  }
  
  command uint8_t BlockingSend.maxPayloadLength[uint8_t client]()
  {
    return call Send.maxPayloadLength[client]();
  }
  
  command void* BlockingSend.getPayload[uint8_t client](message_t* msg, uint8_t len)
  {
    return call Send.getPayload[client](msg, len);
  }
  
  default command collection_id_t CollectionId.fetch[uint8_t id]() { return 0; }
}
