/*
 * Copyright (c) 2008, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2010-02-04 16:31:15 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

 /** Empty placeholder component for PromiscuousModeP. */

#include "TKN154_PHY.h"
#include "TKN154_MAC.h"
module NoPromiscuousModeP 
{
  provides {
    interface Init;
    interface SplitControl as PromiscuousMode;
    interface Get<bool> as PromiscuousModeGet;
    interface FrameRx;
    interface GetNow<token_requested_t> as IsRadioTokenRequested;
  } uses {
    interface TransferableResource as RadioToken;
    interface RadioRx as PromiscuousRx;
    interface RadioOff;
    interface Set<bool> as RadioPromiscuousMode;
  }
}
implementation
{

  command error_t Init.init() { return SUCCESS; }

  /* ----------------------- Promiscuous Mode ----------------------- */

  command bool PromiscuousModeGet.get() { return FALSE; }

  command error_t PromiscuousMode.start() { return FAIL; }

  event void RadioToken.granted() { ASSERT(0);}

  event message_t* PromiscuousRx.received(message_t *frame, const ieee154_timestamp_t *timestamp) { return frame; }

  async event void PromiscuousRx.enableRxDone(){}

  command error_t PromiscuousMode.stop() { return FAIL; }

  async event void RadioOff.offDone() { }

  default event void PromiscuousMode.startDone(error_t error){}
  default event void PromiscuousMode.stopDone(error_t error){}
  async command token_requested_t IsRadioTokenRequested.getNow(){ return FALSE;}
  async event void RadioToken.transferredFrom(uint8_t clientFrom){ASSERT(0);}
}
