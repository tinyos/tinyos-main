/* $Id: CC1000RssiP.nc,v 1.8 2010-06-29 22:07:44 scipio Exp $
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

module CC1000RssiP @safe()
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
	/* The RSSI measurements are assumed to be 10-bits */
	signal Rssi.readDone[currentOp](result, data);
	startNextOp();
      }
  }

  default async event void Rssi.readDone[uint8_t reason](error_t result, uint16_t data) { }
}
