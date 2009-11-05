/*
 * "Copyright (c) 2006 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 */
 
 /*
 * Copyright (c) 2007 Stanford University.
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
 * This is the PrintfP component.  It provides the printf service for printing
 * data over the serial interface using the standard c-style printf command.  
 * Data printed using printf are buffered and only sent over the serial line after
 * the buffer is half full or an explicit call to printfflush() is made.  This 
 * buffer has a maximum size of 250 bytes at present.  This component is wired
 * to a shadowed MainC component so that printf statements can be made anywhere 
 * throughout your code, so long as you include the "printf.h" header file in 
 * every file you wish to use it.  Take a look at the printf tutorial (lesson 15)
 * for more details.
 *
 * The printf service is currently only available for msp430 based motes 
 * (i.e. telos, eyes) and atmega128x based motes (i.e. mica2, micaz, iris).  On the
 * atmega platforms, avr-libc version 1.4 or above must be used.
 */
 
/**
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @date September 18, 2007
 */

#include "printf.h"

#ifdef _H_atmega128hardware_H
static int uart_putchar(char c, FILE *stream);
static FILE atm128_stdout = 
	FDEV_SETUP_STREAM(TCAST(int (*)(char c, FILE *stream), uart_putchar), 
	NULL, _FDEV_SETUP_WRITE);
#endif
#ifdef __M16C62PHARDWARE_H__
	#include "m16c62p_printf.h"
#endif

module PrintfP @safe() {
  provides {
    interface Boot;
  }
  uses {
    interface Boot as MainBoot;
    interface SplitControl as SerialControl;
    interface PrintfQueue<uint8_t> as Queue;

    interface AMSend;
    interface Packet;
    interface Leds;
  }
}
implementation {
  
  enum {
    S_STOPPED,
    S_STARTED,
    S_FLUSHING,
  };

  message_t printfMsg;
  uint8_t state = S_STOPPED;
  
  event void MainBoot.booted() {
    call SerialControl.start();
  }

  event void SerialControl.startDone(error_t error) {
    if (state == S_STOPPED) {
#ifdef _H_atmega128hardware_H
      stdout = &atm128_stdout;
#endif
      atomic state = S_STARTED;
      signal Boot.booted();
    }
  }

  event void SerialControl.stopDone(error_t error) {
    atomic state = S_STOPPED;
  }
  
  task void retrySend() {
    if(call AMSend.send(AM_BROADCAST_ADDR, &printfMsg, sizeof(printf_msg_t)) != SUCCESS)
      post retrySend();
  }
  
  void sendNext() {
    int i;
    printf_msg_t* m = (printf_msg_t*)call Packet.getPayload(&printfMsg, sizeof(printf_msg_t));
    uint16_t length_to_send = (call Queue.size() < sizeof(printf_msg_t)) ? call Queue.size() : sizeof(printf_msg_t);
    memset(m->buffer, 0, sizeof(printf_msg_t));
    for(i=0; i<length_to_send; i++)
      m->buffer[i] = call Queue.dequeue();
    if(call AMSend.send(AM_BROADCAST_ADDR, &printfMsg, sizeof(printf_msg_t)) != SUCCESS)
      post retrySend();  
  }
  
  int printfflush() @C() @spontaneous() {
    atomic {
      if(state == S_FLUSHING)
        return SUCCESS;
      if(call Queue.empty())
        return FAIL;
      state = S_FLUSHING;
    }
    sendNext();
    return SUCCESS;
  }
    
  event void AMSend.sendDone(message_t* msg, error_t error) {    
    if(error == SUCCESS) {
      if(call Queue.size() > 0)
        sendNext();
      else state = S_STARTED;
    }
    else post retrySend();
  }
  
#ifdef _H_msp430hardware_h
  int putchar(int c) __attribute__((noinline)) @C() @spontaneous() {
#endif
#ifdef _H_atmega128hardware_H
  int uart_putchar(char c, FILE *stream) __attribute__((noinline)) @C() @spontaneous() {
#endif
#ifdef __M16C62PHARDWARE_H__
  int lowlevel_putc(int c) __attribute__((noinline)) @C() @spontaneous() {
#endif
    if((state == S_STARTED) && (call Queue.size() >= ((PRINTF_BUFFER_SIZE)/2))) {
      state = S_FLUSHING;
      sendNext();
    }
    atomic {
      if(call Queue.enqueue(c) == SUCCESS)
        return 0;
      else return -1;
    }
  }
}
