// $Id: RadioStressC.nc,v 1.4 2006-12-12 18:22:49 vlahan Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
    RadioCountMsg* rcm = (RadioCountMsg*)call Packet.getPayload(&packet, NULL);
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




