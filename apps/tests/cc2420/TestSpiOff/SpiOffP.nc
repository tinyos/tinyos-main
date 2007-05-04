/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/** 
 * @author David Moss
 */

module SpiOffP {
  uses {
    interface Boot;
    interface Timer<TMilli>;
    interface AMSend;
    interface Receive;
    interface Leds;
    interface SplitControl;
    interface AMPacket;
  }
}

implementation {
  
  message_t myMsg;
  
  bool radioOn;
  
  /***************** Prototypes ****************/
  task void send();
  task void on();
  task void off();
  
  /***************** Boot Events ****************/
  event void Boot.booted() {
    radioOn = FALSE;
    
    if(call AMPacket.address() != 0) {
      call Timer.startPeriodic(768);
      post send();
      
    } else {
      call Timer.startPeriodic(128);
    }
  }
  
  /***************** SplitControl Events ****************/
  event void SplitControl.startDone(error_t error) {
    call Leds.led2On();
    radioOn = TRUE;
  }
  
  event void SplitControl.stopDone(error_t error) {
    call Leds.set(0);
    radioOn = FALSE;
  }
  
  /***************** Send Events ****************/
  event void AMSend.sendDone(message_t *msg, error_t error) {
    call Leds.led1Toggle();
    post send();
  }
  
  /***************** Receive Events ****************/
  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    call Leds.led1Toggle();
    return msg;
  }
  
  /***************** Timer Events *****************/
  event void Timer.fired() {
    if(radioOn) {
      post off();
    } else {
      post on();
    }
  }
  
  /***************** Tasks ****************/
  task void send() {
    if(call AMSend.send(0, &myMsg, 28) != SUCCESS) {
      call Leds.led1Off();
      call Leds.led0Toggle();
      post send();
      
    } else {
      call Leds.led0Off();
    }
  }
  
  task void on() {
    if(call SplitControl.start() != SUCCESS) {
      post on();
    }
  }
  
  task void off() {
    if(call SplitControl.stop() != SUCCESS) {
      post off();
    }
  }
}


