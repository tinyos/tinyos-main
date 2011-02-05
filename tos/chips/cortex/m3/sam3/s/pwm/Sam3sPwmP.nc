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
    interface FunctionWrapper as PwmInterruptWrapper;
    interface HplSam3Pdc as HplPdc;
    interface Leds;
  }
}
implementation
{

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

  command error_t Sam3sPwm.configure(uint32_t frequency, uint16_t period)
  {
    return SUCCESS;
  }

  async command uint32_t getFrequency()
  {

  }

  async command error_t enableCompare(uint8_t compareNumber, uint16_t compareValue)
  {

  }


  async command error_t disableCompare(uint8_t compareNumber)
  {

  }

  async command error_t enableEvent(uint8_t eventNumber, uint8_t compares)
  {

  }

  async command error_t disableEvent(uint8_t eventNumber)
  {

  }
}

