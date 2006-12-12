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

/**
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.4 $
 * @date $Date: 2006-12-12 18:23:31 $ 
 */

#include "printf.h"

#ifdef _H_atmega128hardware_H
static int uart_putchar(char c, FILE *stream);
static FILE atm128_stdout = FDEV_SETUP_STREAM(uart_putchar, NULL, _FDEV_SETUP_WRITE);
#endif

module PrintfP {
  provides {
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
  }
  uses {
  	interface SplitControl as SerialControl;
    interface Leds;
    interface AMSend;
    interface Packet;
  }
}
implementation {
	
  enum {
  	S_STARTED,
  	S_STOPPED,
  	S_FLUSHING,
  };
  
  message_t printfMsg;
  nx_uint8_t buffer[PRINTF_BUFFER_SIZE];
  norace nx_uint8_t* next_byte;
  uint8_t state = S_STOPPED;
  uint8_t bytes_left_to_flush;
  uint8_t length_to_send;
  
  task void retrySend() {
    if(call AMSend.send(AM_BROADCAST_ADDR, &printfMsg, sizeof(PrintfMsg)) != SUCCESS)
      post retrySend();
  }
  
  void sendNext() {
  	PrintfMsg* m = (PrintfMsg*)call Packet.getPayload(&printfMsg, NULL);
  	length_to_send = (bytes_left_to_flush < sizeof(PrintfMsg)) ? bytes_left_to_flush : sizeof(PrintfMsg);
  	memset(m->buffer, 0, sizeof(printfMsg));
  	memcpy(m->buffer, (uint8_t*)next_byte, length_to_send);
    if(call AMSend.send(AM_BROADCAST_ADDR, &printfMsg, sizeof(PrintfMsg)) != SUCCESS)
      post retrySend();  
    else {
      bytes_left_to_flush -= length_to_send;
      next_byte += length_to_send;
    }
  }

  command error_t PrintfControl.start() {
  	if(state == S_STOPPED)
      return call SerialControl.start();
    return FAIL;
  }
  
  command error_t PrintfControl.stop() {
  	if(state == S_STARTED)
      return call SerialControl.stop();
    return FAIL;
  }

  event void SerialControl.startDone(error_t error) {
  	if(error != SUCCESS) {
  	  signal PrintfControl.startDone(error);
  	  return;
  	}
#ifdef _H_atmega128hardware_H
	stdout = &atm128_stdout;
#endif
    atomic {
      memset(buffer, 0, sizeof(buffer));
      next_byte = buffer;
      bytes_left_to_flush = 0; 
      length_to_send = 0;
      state = S_STARTED;
    }
    signal PrintfControl.startDone(error); 
  }

  event void SerialControl.stopDone(error_t error) {
  	if(error != SUCCESS) {
  	  signal PrintfControl.stopDone(error);
  	  return;
  	}
    atomic state = S_STOPPED;
    signal PrintfControl.stopDone(error); 
  }
  
  command error_t PrintfFlush.flush() {
  	atomic {
  	  if(state == S_STARTED && (next_byte > buffer)) {
  	    state = S_FLUSHING;
        bytes_left_to_flush = next_byte - buffer;
  	    next_byte = buffer;
  	  }
  	  else return FAIL;
  	}
  	sendNext();
  	return SUCCESS;
  }
    
  event void AMSend.sendDone(message_t* msg, error_t error) {    
  	if(error == SUCCESS) {
  	  if(bytes_left_to_flush > 0)
  	    sendNext();
  	  else {
        next_byte = buffer;
        bytes_left_to_flush = 0; 
    	length_to_send = 0;
        atomic state = S_STARTED;
	    signal PrintfFlush.flushDone(error);
	  }
	}
	else post retrySend();
  }
  
#ifdef _H_msp430hardware_h
  int putchar(int c) __attribute__((noinline)) @C() @spontaneous() {
#endif
#ifdef _H_atmega128hardware_H
  int uart_putchar(char c, FILE *stream) __attribute__((noinline)) @C() @spontaneous() {
#endif
  	atomic {
  	  if(state == S_STARTED && ((next_byte-buffer+1) < PRINTF_BUFFER_SIZE)) {
  	    *next_byte = c;
  	    next_byte++;
  	    return 0;
  	  }
  	  else return -1;
  	}
  }
}
