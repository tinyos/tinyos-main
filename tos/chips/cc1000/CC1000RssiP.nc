/* $Id: CC1000RssiP.nc,v 1.4 2006-11-07 19:30:45 scipio Exp $
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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 *   RSSI fun. It's used for lots of things, and a request to read it
 *   for one purpose may have to be discarded if conditions change. For
 *   example, if we've initiated a noise-floor measure, but start 
 *   receiving a packet, we have to:<ul>
 *   <li>cancel the noise-floor measure (we don't know if the value will
 *     reflect the received packet or the previous idle state)
 *   <li>start an RSSI measurement so that we can report signal strength
 *     to the application
 *   </ul><p>
 *   This module hides the complexities of cancellation from the rest of
 *   the stack.
 */

module CC1000RssiP
{
  provides {
    interface ReadNow<uint16_t> as Rssi[uint8_t reason];
    async command void cancel();
  }
  uses {
    interface Resource;
    interface ReadNow<uint16_t> as ActualRssi;
  }
}
implementation
{
  enum {
    IDLE = unique(UQ_CC1000_RSSI),
    CANCELLED = unique(UQ_CC1000_RSSI)
  };

  /* All commands are called within atomic sections */
  uint8_t currentOp = IDLE;
  uint8_t nextOp;

  async command void cancel() {
    if (currentOp != IDLE)
      currentOp = CANCELLED;
  }

  event void Resource.granted() {
    call ActualRssi.read();
  }

  async command error_t Rssi.read[uint8_t reason]() {
    if (currentOp == IDLE)
      {
	currentOp = reason;
	if (call Resource.immediateRequest() == SUCCESS)
	  call ActualRssi.read();
	else
	  call Resource.request();
      }
    else
      nextOp = reason;
    return SUCCESS;
  }

  void startNextOp() {
    currentOp = nextOp;
    if (nextOp != IDLE)
      {
	nextOp = IDLE;
	call ActualRssi.read();
      }
    else
      call Resource.release();
  }

  async event void ActualRssi.readDone(error_t result, uint16_t data) {
    atomic
      {
	/* The code assumes that RSSI measurements are 10-bits 
	   (legacy effect) */
	signal Rssi.readDone[currentOp](result, data >> 6);
	startNextOp();
      }
  }

  default async event void Rssi.readDone[uint8_t reason](error_t result, uint16_t data) { }
}
