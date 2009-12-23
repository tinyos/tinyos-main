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
 * BaseStation is a reimplementation of the standard BaseStation application using
 * the TOSThreads thread library.  It transparently forwards any AM messages it
 * receives from its radio interface to its serial interface and vice versa.
 *
 * <p>On the serial link, BaseStation sends and receives simple active
 * messages (not particular radio packets): on the radio link, it
 * sends radio active messages, whose format depends on the network
 * stack being used. BaseStation will copy its compiled-in group ID to
 * messages moving from the serial link to the radio, and will filter
 * out incoming radio messages that do not contain that group ID.</p>
 *
 * <p>BaseStation includes queues in both directions, with a guarantee
 * that once a message enters a queue, it will eventually leave on the
 * other interface. The queues allow the BaseStation to handle load
 * spikes.</p>
 *
 * <p>BaseStation acknowledges a message arriving over the serial link
 * only if that message was successfully enqueued for delivery to the
 * radio link.</p>
 *
 * <p>The LEDS are programmed to toggle as follows:</p>
 * <ul>
 * <li><b>LED0:</b> Message bridged from serial to radio</li>
 * <li><b>LED1:</b> Message bridged from radio to serial</li>
 * <li><b>LED2:</b> Dropped message due to queue overflow in either direction</li>
 * </ul>
 *
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

generic module BaseSendReceiveP() {
  uses {
    interface Boot;
    interface Thread as ReceiveThread;
    interface Thread as SnoopThread;
    interface Thread as SendThread;
    interface ConditionVariable;
    interface Mutex;
    interface Pool<message_t>;
    interface Queue<message_t*>;
    interface Leds;
    
    interface BlockingReceive as BlockingReceiveAny;
    interface BlockingReceive as BlockingSnoopAny;
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
    call SnoopThread.start(NULL);
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
  
  event void SnoopThread.run(void* arg) {   
    message_t* msg;
    call Mutex.lock(&m_pool);
      msg = call Pool.get();
    call Mutex.unlock(&m_pool);
    for(;;) {
      if(call BlockingSnoopAny.receive(msg, 0) == SUCCESS) {
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
  
  default command error_t BlockingSnoopAny.receive(message_t* m, uint32_t timeout) { return FAIL; }
  default command void* BlockingSnoopAny.getPayload(message_t* msg, uint8_t len) { return NULL; }
  default command error_t SnoopThread.start(void* arg) { return FAIL; }
  default command error_t SnoopThread.stop() { return FAIL; }
  default command error_t SnoopThread.pause() { return FAIL; }
  default command error_t SnoopThread.resume() { return FAIL; }
  default command error_t SnoopThread.sleep(uint32_t milli) { return FAIL; }	
}
