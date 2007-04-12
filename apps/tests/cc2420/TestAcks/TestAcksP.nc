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
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */
 
/**
 * Test for radio acknowledgements
 * Program all motes up with ID 1
 *   Led0 = Missed an ack
 *   Led1 = Got an ack
 *   Led2 = Sent a message
 * @author David Moss
 */
 
module TestAcksP {
  uses {
    interface Boot;
    interface SplitControl;
    interface AMSend;
    interface Receive;
    interface Leds;
    interface PacketAcknowledgements;
    interface Timer<TMilli>;
  }
}

implementation {
  
  /** Message to transmit */
  message_t myMsg;
  
  enum {  
    DELAY_BETWEEN_MESSAGES = 50,
  };
  
  
  /***************** Prototypes ****************/
  task void send();
  
  /***************** Boot Events ****************/
  event void Boot.booted() {
    call SplitControl.start();
  }
  
  /***************** SplitControl Events ****************/
  event void SplitControl.startDone(error_t error) {
    post send();
  }
  
  event void SplitControl.stopDone(error_t error) {
  }
  
  /***************** Receive Events ****************/
  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    call Leds.led2Toggle();
    return msg;
  }
  
  /***************** AMSend Events ****************/
  event void AMSend.sendDone(message_t *msg, error_t error) {
    if(call PacketAcknowledgements.wasAcked(msg)) {
      call Leds.led1Toggle();
      call Leds.led0Off();
    } else {
      call Leds.led0Toggle();
      call Leds.led1Off();
    }
    
    if(DELAY_BETWEEN_MESSAGES > 0) {
      call Timer.startOneShot(DELAY_BETWEEN_MESSAGES);
    } else {
      post send();
    }
  }
  
  /***************** Timer Events ****************/
  event void Timer.fired() {
    post send();
  }
  
  /***************** Tasks ****************/
  task void send() {
    call PacketAcknowledgements.requestAck(&myMsg);
    if(call AMSend.send(1, &myMsg, 0) != SUCCESS) {
      post send();
    }
  }
}
