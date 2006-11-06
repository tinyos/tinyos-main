// $Id: TestLplC.nc,v 1.2 2006-11-06 11:56:47 scipio Exp $

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

#include "Timer.h"

/**
 * Simple test code for low-power-listening. Sends a sequence of packets,
 * changing the low-power-listening settings every ~32s. See README.txt
 * for more details.
 *
 *  @author Philip Levis, David Gay
 *  @date   Oct 27 2006
 */

module TestLplC {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl;
    interface LowPowerListening;
  }
}
implementation 
{
  message_t packet;
  bool locked;
  uint8_t counter = 0, sendSkip;
  int16_t sendInterval;

  event void Boot.booted() {
    call SplitControl.start();
  }

  void nextLplState()
  {
    switch (counter >> 5) {
    case 0:
      sendSkip = 0;
      sendInterval = 0;
      call LowPowerListening.setLocalSleepInterval(0);
      break;
    case 1:
      sendInterval = 100; /* Send to sleepy listener */
      break;
    case 2:
      sendInterval = -1; /* Send to listener like us */
      call LowPowerListening.setLocalSleepInterval(250);
      break;
    case 3:
      sendInterval = 0; /* Send to awake listener */
      break;
    case 4:
      sendInterval = -1; /* Send to listener like us */
      call LowPowerListening.setLocalSleepInterval(10);
      break;
    case 5:
      sendSkip = 7; /* Send every 7s */
      call LowPowerListening.setLocalSleepInterval(2000);
      break;
    case 6:
      call LowPowerListening.setLocalDutyCycle(100);
      break;
    case 7:
      call LowPowerListening.setLocalDutyCycle(10);
      break;
    }
  }
  
  event void MilliTimer.fired()
  {
    counter++;
    if (!(counter & 31))
      nextLplState();

    if (!locked && ((counter & sendSkip) == sendSkip))
      {
	if (sendInterval >= 0)
	  call LowPowerListening.setRxSleepInterval(&packet, sendInterval);
	if (call AMSend.send(AM_BROADCAST_ADDR, &packet, 0) == SUCCESS)
	  {
	    call Leds.led0On();
	    locked = TRUE;
	  }
      }
  }

  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len)
  {
    call Leds.led1Toggle();
    return bufPtr;
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error)
  {
    if (&packet == bufPtr)
      {
	locked = FALSE;
	call Leds.led0Off();
      }
  }

  event void SplitControl.startDone(error_t err)
  {
    call MilliTimer.startPeriodic(1000);
  }

  event void SplitControl.stopDone(error_t err) { }
}




