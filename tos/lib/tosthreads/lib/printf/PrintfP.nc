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

#include "printf.h"

#ifdef _H_atmega128hardware_H
static int uart_putchar(char c, FILE *stream);
static FILE atm128_stdout = FDEV_SETUP_STREAM(uart_putchar, NULL, _FDEV_SETUP_WRITE);
#endif

module PrintfP {
  uses {
    interface Boot;
    interface Thread as PrintfThread;
    interface BlockingStdControl as SerialControl;
    interface PrintfQueue<uint8_t> as Queue;
    interface Barrier;
    interface Mutex;

    interface BlockingAMSend;
    interface Packet;
    interface Leds;
  }
}
implementation {
  message_t printfMsg;
  printf_msg_t* printf_payload;
  mutex_t printf_mutex;
  barrier_t flushstart_barrier;
  barrier_t flushdone_barrier;
  
  void flush_buffer();
  
  event void Boot.booted() {
    #ifdef _H_atmega128hardware_H
      stdout = &atm128_stdout;
    #endif
    
    printf_payload = (printf_msg_t*)call Packet.getPayload(&printfMsg, sizeof(printf_msg_t));
    call Mutex.init(&printf_mutex);
    call Barrier.reset(&flushstart_barrier, 2);
    call Barrier.reset(&flushdone_barrier, 2);
    call PrintfThread.start(NULL);
  }
  
  event void PrintfThread.run(void* arg) {
    call SerialControl.start();
    for(;;) {
      call Barrier.block(&flushstart_barrier);
        flush_buffer();
      call Barrier.block(&flushdone_barrier);
    }
  }
  
  void flush_buffer() {
    int i;
    uint16_t q_size;
    uint16_t length_to_send;
    
    call Mutex.lock(&printf_mutex);
      q_size = call Queue.size();
    call Mutex.unlock(&printf_mutex);
    
    while(q_size > 0) {
      memset(printf_payload->buffer, 0, sizeof(printf_msg_t));    
      length_to_send = (q_size < sizeof(printf_msg_t)) ? q_size : sizeof(printf_msg_t);
     
      call Mutex.lock(&printf_mutex); 
        for(i=0; i<length_to_send; i++)
          printf_payload->buffer[i] = call Queue.dequeue();
        q_size = call Queue.size();
      call Mutex.unlock(&printf_mutex);
      call BlockingAMSend.send(AM_BROADCAST_ADDR, &printfMsg, sizeof(printf_msg_t));
    }
  }
  
  int printfflush() @C() @spontaneous() {
    call Barrier.block(&flushstart_barrier);
    call Barrier.reset(&flushstart_barrier, 2);  
    call Barrier.block(&flushdone_barrier);
    call Barrier.reset(&flushdone_barrier, 2);  
    return SUCCESS;
  }
  
  #ifdef _H_msp430hardware_h
  int putchar(int c) __attribute__((noinline)) @C() @spontaneous() {
  #endif
  #ifdef _H_atmega128hardware_H
  int uart_putchar(char c, FILE *stream) __attribute__((noinline)) @C() @spontaneous() {
  #endif
    uint16_t q_size;
    error_t q_error;
    
    call Mutex.lock(&printf_mutex);
      q_error = call Queue.enqueue(c);
      q_size = call Queue.size();
    call Mutex.unlock(&printf_mutex);
    
    if((q_size == PRINTF_BUFFER_SIZE/2))
      printfflush();
    if(q_error == SUCCESS) return 0;
    else return -1;
  }
}
