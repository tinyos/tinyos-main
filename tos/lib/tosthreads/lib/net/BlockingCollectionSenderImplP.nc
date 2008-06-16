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
}
