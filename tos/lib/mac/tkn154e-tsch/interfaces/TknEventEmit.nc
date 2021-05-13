/**
 * Copyright (c) 2015, Technische Universitaet Berlin
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
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 */

#include "tkn_fsm.h"
#include "tkntsch_types.h"
#include "tssm_utils.h"

/**
 * This interface allows to hide the details of emitting events in a component.
 */
interface TknEventEmit
{
  async command tkntsch_status_t emit(tknfsm_event_t e);
  async command tkntsch_status_t scheduleEvent(tknfsm_event_t e,
      tknfsm_delaytype_t delaytype, uint32_t dt);
  async command bool getScheduledEvent(tknfsm_event_t* e,
      tknfsm_delaytype_t* delaytype, uint32_t* t);
  async command uint32_t getReferenceTime();
  async command tkntsch_status_t scheduleEventToReference(tknfsm_event_t e,
      tknfsm_delaytype_t delaytype, uint32_t t0, uint32_t dt);
  async command uint32_t getNow();
  async command void setCorrectionUs(int8_t us);
  async command bool cancelEvent();
  async command void acquireReferenceTime();
  async command int32_t addToReferenceTime(uint32_t dt);
  async command void substractFromReferenceTime(uint32_t dt);
  async command int32_t getReferenceToNowDt();
}
