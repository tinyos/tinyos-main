// $Id: TestAMOnOffC.nc,v 1.5 2010-06-29 22:07:20 scipio Exp $

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
 *  Implementation of the OSKI TestAMOnOff application. This
 *  application has two versions: slave and master. A master is always
 *  on, and transmits data packets at 1Hz. Every 5s, it transmits a
 *  power message. When a slave hears a data message, it toggles its
 *  red led; when it hears a power message, it turns off its radio,
 *  which it turns back on in a few seconds. This essentially tests
 *  whether ActiveMessageC is turning the radio off appropriately.
 *
 *  @author Philip Levis
 *  @date   June 19 2005
 *
 **/

#include "Timer.h"

#if !(defined(SERVICE_SLAVE) || defined(SERVICE_MASTER)) || (defined(SERVICE_SLAVE) && defined(SERVICE_MASTER))
#error "You must compile with either -DSERVICE_SLAVE or -DSERVICE_MASTER"
#endif

module TestAMOnOffC {
  uses {
    interface Leds;
    interface Boot;
    interface Receive as PowerReceive;
    interface AMSend as PowerSend;
    interface Receive as DataReceive;
    interface AMSend as DataSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as RadioControl;
  }
}
implementation {

  message_t packet;

  bool locked;
  uint8_t counter = 0;
  bool on = FALSE;
  event void Boot.booted() {
    call RadioControl.start();
    call MilliTimer.startPeriodic(1000);
  }
  
  event void MilliTimer.fired() {
    call Leds.led2Toggle();
    counter++;
#ifdef SERVICE_SLAVE
    if ((counter % 7) == 0) {
      if (!on) {
        call RadioControl.start();
      }
    }
#endif
#ifdef SERVICE_MASTER
    if (locked) {
      return;
    }
    if (counter % 5) {
      if (call DataSend.send(AM_BROADCAST_ADDR, &packet, 0) == SUCCESS) {
        call Leds.led0Toggle();
        locked = TRUE;
      }
    }
    else {
      if (call PowerSend.send(AM_BROADCAST_ADDR, &packet, 0) == SUCCESS) {
        call Leds.led1Toggle();
        locked = TRUE;
      }
    }
#endif
  }

  event message_t* DataReceive.receive(message_t* bufPtr, 
	   			       void* payload, uint8_t len) {
#ifdef SERVICE_SLAVE 
    call Leds.led0Toggle();
#endif
    return bufPtr;
  }

  event message_t* PowerReceive.receive(message_t* bufPtr, 
	   			        void* payload, uint8_t len) {
#ifdef SERVICE_SLAVE 
    if (on) {
      call RadioControl.stop();
    }
#endif
    return bufPtr;
  }
  
  event void PowerSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

  event void DataSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.start();
    }
    else {
      on = TRUE;
#ifdef SERVICE_SLAVE
    call Leds.led1On();
#endif
    }
  }

  event void RadioControl.stopDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.stop();
    }
    else {
      on = FALSE;
#ifdef SERVICE_SLAVE
    call Leds.led1Off();
#endif
    }
  }
}




