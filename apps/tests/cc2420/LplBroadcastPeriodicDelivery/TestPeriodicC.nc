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
 * This app sends a message from Transmitter node to AM_BROADCAST_ADDR
 * and waits 1000 ms between each delivery so the Rx mote's radio
 * shuts back off and has to redetect to receive the next message. 
 * Receiver: TOS_NODE_ID != 1.
 * Transmitter: TOS_NODE_ID == 1.
 *
 * @author David Moss
 */

#include "TestPeriodic.h"

module TestPeriodicC {
  uses {
    interface Boot;
    interface SplitControl;
    interface LowPowerListening;
    interface AMSend;
    interface Receive;
    interface AMPacket;
    interface Packet;
    interface Leds;
    interface Timer<TMilli>;
  }
}

implementation {
 
  uint8_t count;
  message_t fullMsg;
  bool transmitter;

  uint8_t lastCount;
  
  /**************** Prototypes ****************/
  task void send();
  
  /**************** Boot Events ****************/
  event void Boot.booted() {
    transmitter = (call AMPacket.address() == 1);
    count = 0;
    
    call LowPowerListening.setLocalSleepInterval(1000);
    call SplitControl.start();
  }
  
  event void SplitControl.startDone(error_t error) {
    if(transmitter) {
      post send();
    }
  }
  
  event void SplitControl.stopDone(error_t error) {
  }
  
  
  /**************** Send Receive Events *****************/
  event void AMSend.sendDone(message_t *msg, error_t error) {
    if(transmitter) {
      count++; 
      call Timer.startOneShot(1000);
      call Leds.led0Off();
    }
  }
  
  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    TestPeriodicMsg *periodicMsg = (TestPeriodicMsg *) payload;

    if(!transmitter) {
      if(lastCount == periodicMsg->count) {
        call Leds.led0On();
        call Leds.led1Off();
      } else {
        call Leds.led1On();
        call Leds.led0Off();
      }

      lastCount = periodicMsg->count;

      call Leds.led2Toggle();
    }
    return msg;
  }
  
  /**************** Timer Events ****************/
  event void Timer.fired() {
    if(transmitter) {
      post send();
    }
  }
  
  /**************** Tasks ****************/
  task void send() {
    TestPeriodicMsg *periodicMsg = (TestPeriodicMsg *) call Packet.getPayload(&fullMsg, sizeof(TestPeriodicMsg));
    periodicMsg->count = count;
    call LowPowerListening.setRxSleepInterval(&fullMsg, 1000);
    if(call AMSend.send(AM_BROADCAST_ADDR, &fullMsg, sizeof(TestPeriodicMsg)) != SUCCESS) {
      post send();
    } else {
      call Leds.led0On();
    }
  }
}

