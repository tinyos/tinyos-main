// $Id: TestTimerSyncC.nc,v 1.4 2006-12-12 18:22:51 vlahan Exp $

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
 *  Implementation of the TestTimerSync application.
 *
 *  @author Phil Levis
 *  @author Kevin Klues
 *  @date   Nov 7 2005
 *
 **/

#include "Timer.h"

module TestTimerSyncC {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl;
  }
}
implementation {
  #define PERIOD 500

  message_t syncMsg;

  event void Boot.booted() {
    call SplitControl.start();
  }
 
  event void SplitControl.startDone(error_t err) {
    if(TOS_NODE_ID == 0) {
      call AMSend.send(AM_BROADCAST_ADDR, &syncMsg, 0);
    }
  }

  event void SplitControl.stopDone(error_t err) {
  }

  event void AMSend.sendDone(message_t* msg, error_t error) {
    if(error == SUCCESS) {
      call Leds.led2Toggle();
      call MilliTimer.startOneShot(PERIOD);
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    call Leds.led2Toggle();
    call MilliTimer.startOneShot(PERIOD);
    return msg;
  }

  event void MilliTimer.fired() {
    call Leds.led2Toggle();
    call MilliTimer.startOneShot(PERIOD);
  }
}




