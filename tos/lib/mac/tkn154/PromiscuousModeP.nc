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
 * $Date: 2009-03-24 12:56:46 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_PHY.h"
#include "TKN154_MAC.h"
module PromiscuousModeP 
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
  norace enum promiscuous_state {
    S_STOPPING,
    S_STOPPED,
    S_STARTING,
    S_STARTED,
  } m_state;

  command error_t Init.init()
  {
    m_state = S_STOPPED;
    return SUCCESS;
  }

  /* ----------------------- Promiscuous Mode ----------------------- */

  command bool PromiscuousModeGet.get()
  {
    return (m_state == S_STARTED);
  }

  command error_t PromiscuousMode.start()
  {
    error_t result = FAIL;
    if (m_state == S_STOPPED) {
      m_state = S_STARTING;
      call RadioToken.request();
      result = SUCCESS;
    }
    dbg_serial("PromiscuousModeP", "PromiscuousMode.start -> result: %lu\n", (uint32_t) result);
    return result;
  }

  event void RadioToken.granted()
  {
    call RadioPromiscuousMode.set(TRUE);
    if (call RadioOff.isOff())
      signal RadioOff.offDone();
    else
      call RadioOff.off();
  }

  task void signalStartDoneTask()
  {
    m_state = S_STARTED;
    dbg_serial("PromiscuousModeP", "Promiscuous mode enabled.\n");
    signal PromiscuousMode.startDone(SUCCESS);
  }

  async event void PromiscuousRx.enableRxDone()
  {
    post signalStartDoneTask();
  }

  event message_t* PromiscuousRx.received(message_t *frame)
  {
    if (m_state == S_STARTED) {
      ((ieee154_header_t*) frame->header)->length |= FRAMECTL_PROMISCUOUS;
      return signal FrameRx.received(frame);
    } else
      return frame;
  }

  command error_t PromiscuousMode.stop()
  {
    error_t result = FAIL;
    if (m_state == S_STARTED) {
      m_state = S_STOPPING;
      call RadioOff.off();
      result = SUCCESS;
    }
    dbg_serial("PromiscuousModeP", "PromiscuousMode.stop -> result: %lu\n", (uint32_t) result);
    return result;
  }

  task void continueStopTask()
  {
    call RadioPromiscuousMode.set(FALSE);
    m_state = S_STOPPED;
    call RadioToken.release();
    dbg_serial("PromiscuousModeP", "Promiscuous mode disabled.\n");
    signal PromiscuousMode.stopDone(SUCCESS);
  }

  async event void RadioOff.offDone()
  {
    if (m_state == S_STARTING) {
      call PromiscuousRx.enableRx(0, 0);
    } else
      post continueStopTask();
  }

  async command token_requested_t IsRadioTokenRequested.getNow(){ return m_state == S_STARTING; }
  default event void PromiscuousMode.startDone(error_t error) {}
  default event void PromiscuousMode.stopDone(error_t error) {}
  async event void RadioToken.transferredFrom(uint8_t clientFrom){ASSERT(0);}
}
