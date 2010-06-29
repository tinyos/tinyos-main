// $Id: TestLocalTimeC.nc,v 1.3 2010-06-29 22:07:24 scipio Exp $

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
 * TestLocalTime is a simple application that tests the LocalTimeMilliC
 * componentby sending the current time over the serial port once per
 * second.
 *
 *  @author David Gay
 *  @author Gilman Tolle
 *  @author Philip Levis
 *  
 *  @date   May 24 2007
 *
 **/

#include "Timer.h"
#include "TestLocalTime.h"

module TestLocalTimeC {
  uses {
    interface SplitControl as Control;
    interface Leds;
    interface Boot;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface LocalTime<TMilli>;
  }
}
implementation {
  message_t packet;
  bool locked = FALSE;
  
  event void Boot.booted() {
    call Control.start();
  }
  
  event void Control.startDone(error_t err) {
    if (err == SUCCESS)
      call MilliTimer.startPeriodic(1024);
  }

  event void Control.stopDone(error_t err) { }

  event void MilliTimer.fired() {
    if (!locked)
      {
	test_localtime_msg_t* rcm = (test_localtime_msg_t*)call AMSend.getPayload(&packet, sizeof(test_localtime_msg_t));
	if (call AMSend.maxPayloadLength() < sizeof(test_localtime_msg_t))
	  return;

	rcm->time = call LocalTime.get();
	if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(test_localtime_msg_t)) == SUCCESS)
	  {
	    locked = TRUE;
	    call Leds.led0Toggle();
	  }
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr)
      locked = FALSE;
  }

}




