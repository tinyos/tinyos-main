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
 * $Revision: 1.1 $
 * $Date: 2008-10-21 17:29:00 $
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
  } uses {
    interface Resource as Token;
    interface RadioRx as PromiscuousRx;
    interface RadioOff;
    interface Set<bool> as RadioPromiscuousMode;
    interface Ieee802154Debug as Debug;
  }
}
implementation
{
  enum promiscuous_state {
    S_IDLE,
    S_STARTING,
    S_STARTED,
    S_STOPPING,
  } m_promiscuousState;

  task void prepareDoneTask();
  task void radioOffDoneTask();

  command error_t Init.init()
  {
    m_promiscuousState = S_IDLE;
    return SUCCESS;
  }

/* ----------------------- Promiscuous Mode ----------------------- */

  command bool PromiscuousModeGet.get()
  {
    return (m_promiscuousState == S_STARTED);
  }

  command error_t PromiscuousMode.start()
  {
    if (m_promiscuousState != S_IDLE)
      return FAIL;
    m_promiscuousState = S_STARTING;
    call Token.request();
    call Debug.log(LEVEL_INFO, EnableRxP_PROMISCUOUS_REQUEST, m_promiscuousState, 0, 0);
    call Debug.flush();
    return SUCCESS;
  }

  event void Token.granted()
  {
    if (m_promiscuousState != S_STARTING){
      call Token.release();
      return;
    }
    call RadioPromiscuousMode.set(TRUE);
    if (call PromiscuousRx.prepare() != IEEE154_SUCCESS){
      m_promiscuousState = S_IDLE;
      call Token.release();
      call Debug.log(LEVEL_IMPORTANT, EnableRxP_RADIORX_ERROR, 0, 0, 0);
      signal PromiscuousMode.startDone(FAIL);
    }
  }

  async event void PromiscuousRx.prepareDone()
  {
    post prepareDoneTask();
  }

  task void prepareDoneTask()
  {
    if (m_promiscuousState != S_STARTING){
      call Token.release();
      return;
    }    
    m_promiscuousState = S_STARTED;
    call PromiscuousRx.receive(NULL, 0);
    signal PromiscuousMode.startDone(SUCCESS);
    call Debug.log(LEVEL_INFO, EnableRxP_PROMISCUOUS_ON, m_promiscuousState, 0, 0);
  }

  event message_t* PromiscuousRx.received(message_t *frame, ieee154_reftime_t *timestamp)
  {
    if (m_promiscuousState == S_STARTED){
      ((ieee154_header_t*) frame->header)->length |= FRAMECTL_PROMISCUOUS;
      return signal FrameRx.received(frame);
    } else
      return frame;
  }

  command error_t PromiscuousMode.stop()
  {
    if (m_promiscuousState != S_STARTED)
      return FAIL;
    m_promiscuousState = S_STOPPING;
    call RadioOff.off();
    return SUCCESS;
  }

  async event void RadioOff.offDone()
  {
    post radioOffDoneTask();
  }

  task void radioOffDoneTask()
  {
    if (m_promiscuousState != S_STOPPING){
      call Token.release();
      return;
    }
    m_promiscuousState = S_IDLE;
    call RadioPromiscuousMode.set(FALSE);
    call Token.release();
    signal PromiscuousMode.stopDone(SUCCESS);
    call Debug.log(LEVEL_INFO, EnableRxP_PROMISCUOUS_OFF, m_promiscuousState, 0, 0);
  }

  default event void PromiscuousMode.startDone(error_t error){}
  default event void PromiscuousMode.stopDone(error_t error){}
}
