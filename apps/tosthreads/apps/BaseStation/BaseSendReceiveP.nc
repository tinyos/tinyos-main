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
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

generic module BaseSendReceiveP() {
  uses {
    interface Boot;
    interface Thread as ReceiveThread;
    interface Thread as SendThread;
    interface ConditionVariable;
    interface Mutex;
    interface Pool<message_t>;
    interface Queue<message_t*>;
    interface Leds;
    
    interface BlockingReceive as BlockingReceiveAny;
    interface BlockingAMSend as BlockingAMSend[uint8_t id];
    interface Packet as ReceivePacket;
    interface Packet as SendPacket;
    interface AMPacket as ReceiveAMPacket;
    interface AMPacket as SendAMPacket;
  }
}

implementation {
  condvar_t c_queue, c_pool;
  mutex_t m_queue, m_pool;
  
  event void Boot.booted() {
    call ConditionVariable.init(&c_queue);
    call ConditionVariable.init(&c_pool);
    call Mutex.init(&m_queue);
    call Mutex.init(&m_pool);
    call ReceiveThread.start(NULL);
    call SendThread.start(NULL);
  }
  
  event void ReceiveThread.run(void* arg) {   
    message_t* msg;
    call Mutex.lock(&m_pool);
      msg = call Pool.get();
    call Mutex.unlock(&m_pool);
    for(;;) {
      if(call BlockingReceiveAny.receive(msg, 0) == SUCCESS) {
        call Leds.led0Toggle();
        
        call Mutex.lock(&m_queue);
          call Queue.enqueue(msg);
        call Mutex.unlock(&m_queue);
        if( call Queue.size() == 1 ) {
          call ConditionVariable.signalAll(&c_queue);
        }
        
        call Mutex.lock(&m_pool);
          while( call Pool.empty() )
            call ConditionVariable.wait(&c_pool, &m_pool);
          msg = call Pool.get();
        call Mutex.unlock(&m_pool);
        
      }
      else call Leds.led2Toggle();
    }
  }
  
  event void SendThread.run(void* arg) {  
    message_t* msg;
    am_id_t id;
    am_addr_t source;
    am_addr_t dest;
    uint8_t len;  
  
    for(;;) {
      call Mutex.lock(&m_queue);
        while( call Queue.empty() )
          call ConditionVariable.wait(&c_queue, &m_queue);
        msg = call Queue.dequeue();
      call Mutex.unlock(&m_queue);
      
      id = call ReceiveAMPacket.type(msg);
      source = call ReceiveAMPacket.source(msg);
      dest = call ReceiveAMPacket.destination(msg);
      len = call ReceivePacket.payloadLength(msg);
      
      call SendPacket.clear(msg);
      call SendAMPacket.setSource(msg, source);
      
      call BlockingAMSend.send[id](dest, msg, len);
      call Leds.led1Toggle();
      
      call Mutex.lock(&m_pool);
        call Pool.put(msg);
      call Mutex.unlock(&m_pool);
      if( call Pool.size() == 1 ) {
        call ConditionVariable.signalAll(&c_pool);
      }
    }
  }
}
