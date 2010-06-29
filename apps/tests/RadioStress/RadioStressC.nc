// $Id: RadioStressC.nc,v 1.6 2010-06-29 22:07:20 scipio Exp $

/*									tab:4
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 *  Implementation of the OSKI RadioCountToLeds application. This
 *  application periodically broadcasts a 16-bit counter, and displays
 *  broadcasts it hears on its LEDs.
 *
 *  @author Philip Levis
 *  @date   June 6 2005
 *
 **/

#include "Timer.h"
#include "RadioStress.h"

module RadioStressC {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface SplitControl as RadioControl;
    interface Packet;
    interface Timer<TMilli>;
    interface PacketAcknowledgements as Acks;
  }
}
implementation {

  message_t packet;

  bool locked;
  bool resourceHeld;
  uint32_t txCounter = 0;
  uint32_t ackCounter = 0;
  uint32_t rxCounter = 0;
  int16_t timerCounter = -1;
  uint16_t taskCounter = 0;
  uint16_t errorCounter = 0;
  
  event void Boot.booted() {
    call Leds.led0On();
    call RadioControl.start();
  }

  task void sendTask();

  void sendPacket() {
    RadioCountMsg* rcm = (RadioCountMsg*)call Packet.getPayload(&packet, sizeof(RadioCountMsg));
    if (locked) {return;}
    rcm->counter = txCounter;
    if (call AMSend.send(AM_BROADCAST_ADDR, &packet, 2) == SUCCESS) {
      locked = TRUE;
    }
    else {
      post sendTask();
    }
  }

  task void sendTask() {
    taskCounter++;
    sendPacket();
  }
  
  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.start();
    }
    else {
      call Leds.led1On();
      call Timer.startPeriodic(1000);
      //call Acks.enable();
    }
  }

  event void RadioControl.stopDone(error_t err) {

  }


  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
    rxCounter++;
    if ((rxCounter % 32) == 0) {
      call Leds.led0Toggle();
    }
    return bufPtr;
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (error != SUCCESS) {
      errorCounter++;
    }
    txCounter++;
    if (txCounter % 32 == 0) {
      call Leds.led1Toggle();
    }
    if (call Acks.wasAcked(bufPtr)) {
      ackCounter++;
      if (ackCounter % 32 == 0) {
	call Leds.led2Toggle();
      }
    }
    locked = FALSE;
    sendPacket();
  }

  event void Timer.fired() {
    call Leds.led2Toggle();
    timerCounter++;
    if (!locked) {
      sendPacket();
    }
	
  }

}




