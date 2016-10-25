/*
 * Copyright (c) 2011 University of Utah. 
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
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS
 * IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR ITS
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Thomas Schmid
 */

#include "sam3spwmhardware.h"

module Sam3sPwmP
{

  provides
  {
    interface StdControl;
    interface Sam3sPwm;
  }
  uses
  {
    interface HplNVICInterruptCntl as PwmInterrupt;
    interface HplSam3PeripheralClockCntl as PwmClockControl;
    interface HplSam3Clock as ClockConfig;
    interface HplSam3Pdc as HplPdc;
    interface McuSleep;
    interface Leds;
  }
}
implementation
{
  norace uint32_t actualFrequency = 0;

  command error_t StdControl.start()
  {
    atomic
    {
      call PwmClockControl.enable();

      /* Configure interrupts */
      call PwmInterrupt.configure(IRQ_PRIO_PWM);
    }
    return SUCCESS;
  }

  command error_t StdControl.stop()
  {
    atomic
    {
      call PwmClockControl.disable();
      call PwmInterrupt.disable();
    }
    return SUCCESS;
  }

  async command error_t Sam3sPwm.configure(uint32_t frequency)
  {
    uint8_t i;

    // get the main clock speed in khz
    uint32_t mck = call ClockConfig.getMainClockSpeed();

    uint32_t divider = mck / frequency;

    pwm_clk_t clk = PWM->clk;
    volatile pwm_channel_t *ch0 = &(PWM->channel[0]);
    pwm_cmr_t cmr = ch0->cmr;

    // disable channel 0
    PWM->dis.flat = 1;

    if(divider == 0)
    {
      // mck is too slow for requested frequency.
      return FAIL;
    }

    // check if we can use modulo counter clocks
    for(i=0; i<11; i++)
    {
      if(divider == (1 << i))
      {
        // GREAT!
        break;
      }
    }

    if(i < 11)
    {
      // we can use the modulo counter
      cmr.bits.cpre = i;
      actualFrequency = (mck >> i);
    } else {
      // we have to use the divider too
      cmr.bits.cpre = PWM_CMR_CPRE_CLKA;

      // find the right combination of modulo counter and divider that matches
      // the requested frequency the closest.
      for(i=0; i<11; i++)
      {
        divider = (mck >> i) / frequency;

        if(divider < 255)
        {
          clk.bits.diva = divider;
          clk.bits.prea = i;
          actualFrequency = (mck >> i) / divider;
          break;
        }
      }
      if(i >= 11)
      {
        // we couldn't find a combination of modulo counter and divider that
        // works.
        return FAIL;
      }
    }

    // clock setup done.

    PWM->clk = clk;
    ch0->cmr = cmr;

    // enable channel 0
    PWM->ena.flat = 1;

    return SUCCESS;
  }

  async command void Sam3sPwm.setPeriod(uint16_t period)
  {

    volatile pwm_channel_t *ch0 = &(PWM->channel[0]);
    pwm_cdtyupd_t cdtyupd = ch0->cdtyupd;
    pwm_cprdupd_t cprdupd = ch0->cprdupd;

    // setup period and duty-cycle.
    cdtyupd.bits.cdtyupd = period / 2; // 50% duty cycle
    cprdupd.bits.cprdupd = period; // count at which counter resets to 0
    ch0->cdtyupd = cdtyupd;
    ch0->cprdupd = cprdupd;

  }

  async command uint32_t Sam3sPwm.getFrequency()
  {
    return actualFrequency;
  }

  async command error_t Sam3sPwm.enableCompare(uint8_t compareNumber, uint16_t compareValue)
  {
    volatile pwm_comparison_t *compare;
    pwm_cmpm_t cmpm;
    pwm_cmpv_t cmpv;

    if(compareNumber < 8)
    {
      compare = &(PWM->comparison[compareNumber]);
      cmpm = compare->cmpm;
      cmpv = compare->cmpv;
    } else {
      return FAIL;
    }
    // turn of comparison
    compare->cmpm.flat = 0;

    cmpv.bits.cv = compareValue;

    cmpm.bits.cen = 1;

    compare->cmpv = cmpv;
    compare->cmpm = cmpm;

    return SUCCESS;
  }


  async command error_t Sam3sPwm.disableCompare(uint8_t compareNumber)
  {
    volatile pwm_comparison_t *compare;

    if(compareNumber < 8)
    {
      compare = &(PWM->comparison[compareNumber]);
    } else {
      return FAIL;
    }
    // turn of comparison
    compare->cmpm.flat = 0;

    return SUCCESS;
  }

  async command error_t Sam3sPwm.setEventCompares(uint8_t eventNumber, uint8_t compares)
  {
    switch(eventNumber)
    {
      case 0:
        PWM->elm0r.flat = compares;
        break;

      case 1:
        PWM->elm1r.flat = compares;
        break;

      default:
        return FAIL;
    }
    return SUCCESS;
  }

  async event void ClockConfig.mainClockChanged(){}
}

