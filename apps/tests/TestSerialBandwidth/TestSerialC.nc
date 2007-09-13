// $Id: TestSerialC.nc,v 1.5 2007-09-13 23:10:21 scipio Exp $

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
 * Application to test that the TinyOS java toolchain can communicate
 * with motes over the serial port. The application sends packets to
 * the serial port at 1Hz: the packet contains an incrementing
 * counter. When the application receives a counter packet, it
 * displays the bottom three bits on its LEDs. This application is
 * very similar to RadioCountToLeds, except that it operates over the
 * serial port. There is Java application for testing the mote
 * application: run TestSerial to print out the received packets and
 * send packets to the mote.
 *
 *  @author Gilman Tolle
 *  @author Philip Levis
 *  
 *  @date   Aug 12 2005
 *
 **/

#include "Timer.h"
#include "TestSerial.h"

module TestSerialC {
  uses {
    interface SplitControl as Control;
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface Packet;
  }
}
implementation {

  message_t packet;

  bool locked;
  bool afap = TRUE;
  uint32_t interval = 10;

  uint16_t counter = 0;
  
  event void Boot.booted() {
    call Control.start();
  }
  
  event void MilliTimer.fired() {
    counter++;
    if (locked) {
      if (afap) call MilliTimer.startPeriodic(interval);

      return;
    }
    else {
      TestSerialMsg* rcm = (TestSerialMsg*)call Packet.getPayload(&packet, sizeof(TestSerialMsg));
      if (rcm == NULL || call Packet.maxPayloadLength() < sizeof(TestSerialMsg)) {
	return;
      }

      rcm->counter = counter;
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(TestSerialMsg)) == SUCCESS) {
	locked = TRUE;
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {

    if (len != sizeof(TestSerialMsg)) {return bufPtr;}
    else {
      TestSerialMsg* rcm = (TestSerialMsg*)payload;
      if (rcm->counter & 0x1) {
	call Leds.led0On();
      }
      else {
	call Leds.led0Off();
      }
      if (rcm->counter & 0x2) {
	call Leds.led1On();
      }
      else {
	call Leds.led1Off();
      }
      if (rcm->counter & 0x4) {
	call Leds.led2On();
      }
      else {
	call Leds.led2Off();
      }
      return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
      // as fast as possible
      if (afap){
        TestSerialMsg* rcm = (TestSerialMsg*)call Packet.getPayload(&packet, sizeof(TestSerialMsg));
	if (rcm == NULL || call Packet.payloadLength(&packet) != sizeof(TestSerialMsg)) {
	  return;
	}
        counter++;
        rcm->counter = counter;
        call Leds.led0Toggle();
        if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(TestSerialMsg)) == SUCCESS) {
          locked = TRUE;
        }
        else {
          call MilliTimer.startOneShot(interval);
        }
      }
    }  
  }
  
  event void Control.startDone(error_t err) {
    if (err == SUCCESS) {
      if (afap){
        call MilliTimer.startOneShot(interval);
      }
      else {
        call MilliTimer.startPeriodic(interval);
      }
    }
  }
  event void Control.stopDone(error_t err) {}
}




