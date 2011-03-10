/*
 * Copyright (c) 2011 The Regents of the University  of California.
 * All rights reserved."
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
 * - Neither the name of the copyright holders nor the names of
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
 */

/**
 * AC Mote and Energy Meter using ADE7753
 *
 * @author Fred Jiang <fxjiang@eecs.berkeley.edu>
 * @author Thomas Schmid (generalized module)
 */

#include <Timer.h>
#include <ADE7753.h>

#include <Assert.h>

#include "ACMeter.h"

module ACMeterP {
  provides {
    interface SplitControl;
    interface ReadStream<uint32_t> as ReadEnergy;
    interface GetSet<acmeter_state_t> as RelayConfig;
    interface GetSet<uint8_t> as GainConfig;
    interface Get<uint32_t> as GetPeriod;
  }

  uses {
    interface Alarm<TMilli, uint32_t> as SampleAlarm;
    interface Leds;
    interface ADE7753;
    interface SplitControl as MeterControl;
    interface GeneralIO as onoff;
  }
} 

implementation {

  acmeter_state_t onoff_state;
  norace uint32_t m_gain;
  uint32_t m_period, m_last;
  norace uint16_t m_mode;
  bool dirty;

  uint32_t *current_buffer, *deliver_buffer;
  uint16_t  current_buffer_size, deliver_buffer_size;
  uint16_t  current_buffer_idx;
  struct acmeter_buffer *extra_buffers = NULL;

  norace enum {
    OFF,
    INIT,
    ON,
  } state = OFF;

  norace enum {
    SET_MODE,
    SET_GAIN,
    DONE,
  } initState = SET_MODE;

  task void signalStartDone() {
    signal SplitControl.startDone(SUCCESS);
  }

  // this state machine drives the initialization
  task void init_task() {
    ASSERT(state == INIT);

    switch(initState) {
      case SET_MODE:
        call Leds.led2On();
        m_mode = (1<<ADE7753_MODE_POAM) | 
                 (1<<ADE7753_MODE_DISCF) | 
                 (1<<ADE7753_MODE_DISSAG);
        initState = SET_GAIN;
        call ADE7753.setReg(ADE7753_MODE, 3, m_mode);
        break;

      case SET_GAIN:
        call Leds.led2Off();
        call Leds.led1On();
        m_gain = (ADE7753_GAIN_2        << ADE7753_GAIN_PGA_CH1) |
                 (ADE7753_GAIN_2        << ADE7753_GAIN_PGA_CH2) |
                 (ADE7753_GAIN_SCALE_05 << ADE7753_GAIN_SCALE_CH1);
        initState = DONE;
        call ADE7753.setReg(ADE7753_GAIN, 2, m_gain);
        break;

      case DONE:
        call Leds.led1Off();
        call Leds.led0On();
        state = ON;
        post signalStartDone();
        break;

      default:
        ASSERT(1);
    }

  }

  command error_t SplitControl.start() {
    if (state != OFF) {
      return EALREADY;
    }

    atomic {
      onoff_state = ACMETER_ON;
      state = INIT;
      initState = SET_MODE;
    }

    call onoff.makeOutput();
    call onoff.set();
    call MeterControl.start();

    return SUCCESS;
  }

  event void MeterControl.startDone(error_t err) {
    post init_task();

    atomic
    {
      current_buffer = NULL;
      deliver_buffer = NULL;
      extra_buffers = NULL;
      current_buffer_size = current_buffer_idx = 0;
    }

  }

  event void MeterControl.stopDone(error_t err) {
    signal SplitControl.stopDone(err);
  }

  command error_t SplitControl.stop() {
    if (current_buffer != NULL) {
      return EBUSY;
    }

    call SampleAlarm.stop();
    call MeterControl.stop();

    state = OFF;
  }


  /******* Relay config **********/  
  command void RelayConfig.set(acmeter_state_t acState) {
    if (acState == ACMETER_ON) {
      call onoff.set();
    } else {
      call onoff.clr();
    }
    onoff_state = acState;
  }

  command acmeter_state_t RelayConfig.get() {
    return onoff_state;
  }

  /****** Gain setup ******/
  command void GainConfig.set(uint8_t newgain) {
    // changes only take effect on restart
    m_gain = newgain;
  }

  command uint8_t GainConfig.get() {
    return m_gain;
  }

  /******* Energy Reading **********/

  command uint32_t GetPeriod.get() {
    return m_period;
  }

  /* code for buffered reading  */
  command error_t ReadEnergy.read(uint32_t usPeriod) {
    atomic {
      if (call SampleAlarm.isRunning()) 
        return EBUSY;

      // convert us to TMilli tics without overflow, and set the first reading
      m_period = (usPeriod / 1000);
      m_last = call SampleAlarm.getNow();
      call SampleAlarm.startAt(m_last, m_period);
    }

    return SUCCESS;
  }

  async event void SampleAlarm.fired() {
    // at 1Hz, reading RENERGY is equal to power
    call ADE7753.getReg(ADE7753_RAENERGY, 4);

    // reset the alarm
    atomic {
      m_last += m_period;
      call SampleAlarm.startAt(m_last, m_period);
    }
  }

  task void readDone_task() {
    signal ReadEnergy.readDone(SUCCESS, 1000*m_period);
  }

  task void bufferDone_task() {
    atomic {
      signal ReadEnergy.bufferDone(SUCCESS, deliver_buffer, deliver_buffer_size);
      deliver_buffer = NULL;
      deliver_buffer_size = 0;
    }
  }

  void readRAEnergy(uint32_t val) {
    atomic {
      if (current_buffer == NULL) {
        post readDone_task();
        call SampleAlarm.stop();
      } else {

        if (current_buffer_idx < current_buffer_size) {
          current_buffer[current_buffer_idx++] = val;
        }

        if (current_buffer_idx == current_buffer_size) {

          // if we can't deliver the buffers fast enough, we'll drop
          // readings until we catch up.
          if (deliver_buffer == NULL) {
            deliver_buffer = current_buffer;
            deliver_buffer_size = current_buffer_idx;
            post bufferDone_task();

            if (extra_buffers != NULL) {
              current_buffer = (uint32_t *)extra_buffers;
              current_buffer_idx = 0;
              current_buffer_size = extra_buffers->sz;

              extra_buffers = extra_buffers->next;
            } else {
              current_buffer = NULL;
            }
          }
        }
      }
    }
  }

  async event void ADE7753.getRegDone( error_t error, uint8_t regAddr, uint32_t val, uint16_t len) {

    if (state == INIT) {
      post init_task();
      return;
    }

    ASSERT(state == ON);

    switch(regAddr) {
      case ADE7753_RAENERGY:
        readRAEnergy(val);
        break;

      default:
        ASSERT(1);
    }
  }

  /* adding buffers */
  command error_t ReadEnergy.postBuffer(uint32_t *buf, uint16_t count) {
    atomic {
      if (current_buffer == NULL) {
        current_buffer = buf;
        current_buffer_size = count;
        current_buffer_idx = 0;
      } else {
        struct acmeter_buffer *newbuf = (struct acmeter_buffer *)buf;
        if (count * sizeof(uint32_t) < sizeof(struct acmeter_buffer)) {
          return ESIZE;
        }
        newbuf->sz = count;
        newbuf->next = extra_buffers;
        extra_buffers = newbuf;
      }
    }
    return SUCCESS;
  }

  async event void ADE7753.setRegDone( error_t error, uint8_t regAddr, uint32_t val, uint16_t len) {
    if (state == INIT) {
      post init_task();
      return;
    }

    ASSERT(state == ON);

    switch (regAddr) {
      default:
        ASSERT(1);
    }
  }

}
