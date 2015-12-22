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
 * @author Jasper Büsch <buesch@tkn.tu-berlin.de>
 */

#include "tkn_fsm.h"
#include "tkntsch_types.h"
#include "tssm_utils.h"

/**
 * This Module encapsulates the event generation mechanisms of the TKN TSCH.
 */
module TknTschEventEmitterP
{
  provides {
    interface TknEventEmit as EventEmit;
    interface TknEventReceive as EventReceive;
  }
  uses {
    interface Alarm<T32khz,uint32_t> as TssmAlarm32;
    interface TknTschDebugHelperTssm as DebugHelper;
  }
}
implementation
{
  struct {
    tknfsm_event_t e;
    tknfsm_delaytype_t delaytype;
    uint32_t t0;
    uint32_t dt;
  } scheduled;
  uint32_t m_timerReferenceTime;
  uint32_t timestamp;
  int8_t correction_ticks = 0;

  uint32_t m_systematicTimingErrorUs = 0;

  void handleAllEvents() {
    // TODO loop over all scheduled events

    // Doing the easy thing: just a single event
    tknfsm_event_t e;
    tknfsm_delaytype_t delaytype;

    atomic {
      delaytype = scheduled.delaytype;
      e = scheduled.e;
    }
    while (delaytype == TSCH_DELAY_IMMEDIATE) {
      // reset the event queue
      atomic scheduled.delaytype = TSCH_DELAY_NONE;

      signal EventReceive.receive(e);

      atomic {
        delaytype = scheduled.delaytype;
        e = scheduled.e;
      }
    }
  }

  // TODO What about remaining event(s) in the queue?
  async command tkntsch_status_t EventEmit.emit(tknfsm_event_t e) {
    signal EventReceive.receive(e);
    handleAllEvents();
    return TKNTSCH_SUCCESS;
  }

  async command uint32_t EventEmit.getReferenceTime() {
    atomic return m_timerReferenceTime;
  }

  async command tkntsch_status_t EventEmit.scheduleEventToReference(tknfsm_event_t e,
      tknfsm_delaytype_t delaytype, uint32_t t0, uint32_t dt) {
    // TODO handle the other delay types too
    tknfsm_delaytype_t d_type;
    atomic {
      d_type = scheduled.delaytype;
    }

    if (d_type != TSCH_DELAY_NONE)
      return TKNTSCH_BUSY;

    switch (delaytype) {
      case TSCH_DELAY_IMMEDIATE:
        break;

      case TSCH_DELAY_NONE:
        atomic scheduled.delaytype = TSCH_DELAY_NONE;
        return TKNTSCH_SUCCESS;
        break;

      case TSCH_DELAY_SHORT:
        atomic {
          TSSM_ALARM32_START_AT_US(t0, dt);
        }
        break;

      case TSCH_DELAY_LONG:
        // TODO implement long delays
        return TKNTSCH_INVALID_PARAMETER;
        break;

      default:
        return TKNTSCH_INVALID_PARAMETER;
    }

    atomic {
      scheduled.delaytype = delaytype;
      scheduled.e = e;
      scheduled.dt = dt;
    }

    return TKNTSCH_SUCCESS;

  }

  async command tkntsch_status_t EventEmit.scheduleEvent(tknfsm_event_t e,
      tknfsm_delaytype_t delaytype, uint32_t dt)
  {
    atomic return call EventEmit.scheduleEventToReference(e, delaytype, m_timerReferenceTime, dt);
  }

  async command void EventEmit.acquireReferenceTime() {
    atomic m_timerReferenceTime = call TssmAlarm32.getNow();
  }

  async command void EventEmit.substractFromReferenceTime(uint32_t dt) {
    atomic m_timerReferenceTime -= TSSM_ALARM32_TIME_FROM_US(dt);
  }

  async command int32_t EventEmit.addToReferenceTime(uint32_t dt) {
    uint32_t fullTssmClkTickErrors;
    atomic {
      m_systematicTimingErrorUs += TSSM_ALARM32_TIME_FROM_US_ERROR(dt);
      fullTssmClkTickErrors = TSSM_ALARM32_TIME_FROM_US(m_systematicTimingErrorUs);
      if (fullTssmClkTickErrors > 0) {
        uint8_t usCorrection = TSSM_ALARM32_TIME_TO_US(fullTssmClkTickErrors);
        dt += usCorrection;
        m_systematicTimingErrorUs -= usCorrection;
      }

      m_timerReferenceTime += TSSM_ALARM32_TIME_FROM_US(dt);
    }

    return TSSM_ALARM32_TIME_FROM_US_ERROR(dt);
  }

  async command int32_t EventEmit.getReferenceToNowDt() {
    atomic {
      int32_t dt = (call TssmAlarm32.getNow()) - m_timerReferenceTime;
      if (abs(dt) > 0x7fffffff) {
        dt = ~(m_timerReferenceTime - (call TssmAlarm32.getNow())) + 1;
      }
      return TSSM_ALARM32_TIME_TO_US(dt);
    }
  }

  async command uint32_t EventEmit.getNow() {
    return TSSM_ALARM32_TIME_TO_US(call TssmAlarm32.getNow());
  }

  async command bool EventEmit.getScheduledEvent(tknfsm_event_t* e,
      tknfsm_delaytype_t* delaytype, uint32_t* t) {
    atomic {
      if (e != NULL) *e = scheduled.e;
      if (t != NULL) *t = timestamp; //call TssmAlarm32.getAlarm();
      if (delaytype != NULL) *delaytype = scheduled.delaytype;

      if (scheduled.delaytype == TSCH_DELAY_NONE) {
        return FALSE;
      }
      else {
        return TRUE;
      }
    }
  }

  async command void EventEmit.setCorrectionUs(int8_t us) {
    atomic correction_ticks += us;
  }

  async command bool EventEmit.cancelEvent() {
    atomic {
      call TssmAlarm32.stop();
      if (scheduled.delaytype == TSCH_DELAY_NONE) {
        return FALSE;
      }

      scheduled.delaytype = TSCH_DELAY_NONE;
      return TRUE;
    }
  }

  async event void TssmAlarm32.fired() {
    tknfsm_event_t e;
    call DebugHelper.startOfAlarmIrq();
    atomic {
      e = scheduled.e;
      // resetting event emitter state
      scheduled.delaytype = TSCH_DELAY_NONE;
    }

    call EventEmit.emit(e);
    call DebugHelper.endOfAlarmIrq();
  }
}
