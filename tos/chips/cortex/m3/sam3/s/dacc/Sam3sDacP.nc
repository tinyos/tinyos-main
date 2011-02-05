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

#include "sam3sdacchardware.h"

module Sam3sDacP
{

  provides
  {
    interface StdControl;
    interface Sam3sDac;
  }
  uses
  {
    interface HplNVICInterruptCntl as DacInterrupt;
    interface HplSam3GeneralIOPin as DacPin0;
    interface HplSam3GeneralIOPin as DacPin1;
    interface HplSam3PeripheralClockCntl as DacClockControl;
    interface HplSam3Clock as ClockConfig;
    interface FunctionWrapper as DacInterruptWrapper;
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
      DACC->cr.flat = 0x1; // software reset
      call DacClockControl.enable();

      /* Configure interrupts */
      call DacInterrupt.configure(IRQ_PRIO_DAC);

      /* Set IO line */
      call DacPin0.disablePioControl(); // Disable whatever is set currently
      call DacPin0.selectPeripheralD();

      call DacPin1.disablePioControl(); // Disable whatever is set currently
      call DacPin1.selectPeripheralD();
    }
    return SUCCESS;
  }

  command error_t StdControl.stop()
  {
    atomic
    {
      call DacClockControl.disable();
      call DacInterrupt.disable();
    }
    return SUCCESS;
  }

  command error_t Sam3sDac.configure(
      bool triggerEn,     // enable external trigger mode
      uint8_t triggerSel, // select trigger source
      bool wordTransfer,  // 1: word transfer, 0: half-word
      bool sleep,         // 1: sleep mode, 0: normal mode
      bool fastWakeUp,
      uint8_t refreshPeriod,
      uint8_t userSel,    // select channel
      bool tagSelection,  // 1: bits 13-12 in data select channel
      bool maxSpeed,      // 1: max speed mode enabled
      uint8_t startupTime)
  {
    dacc_mr_t mr;

    mr.bits.trgen = triggerEn;
    mr.bits.trgsel = triggerSel & 0x7;
    mr.bits.word = wordTransfer;
    mr.bits.sleep = sleep;
    mr.bits.fastwkup = fastWakeUp;
    mr.bits.refresh = refreshPeriod;
    mr.bits.user_sel = userSel;
    mr.bits.tag = tagSelection;
    mr.bits.maxs = maxSpeed;
    mr.bits.startup = startupTime & 0x3F;

    DACC->mr = mr;

    return SUCCESS;
  }

  async command error_t Sam3sDac.enable(uint8_t channel)
  {
    if(channel >= DACC_MAX_CHANNELS)
      return FAIL;

    DACC->cher.flat = (1 << channel);
    return SUCCESS;
  }

  async command error_t Sam3sDac.disable(uint8_t channel)
  {
    if(channel >= DACC_MAX_CHANNELS)
      return FAIL;

    DACC->chdr.flat = (1 << channel);
  }

  async command error_t Sam3sDac.set(uint32_t data)
  {
    if(DACC->isr.bits.txrdy)
    {
      DACC->cdr.bits.data = data;
      return SUCCESS;
    } else {
      return EBUSY;
    }
  }

  async event void ClockConfig.mainClockChanged(){}

  async command uint32_t setFrequency(uint32_t frequency)
  {

  }

  async command error_t setBuffer(uint32_t *buffer, uint16_t length)
  {

  }

  event void bufferDone(error_t error, uint32_t *buffer, uint32_t *nextBuffer)
  {

  }

}

