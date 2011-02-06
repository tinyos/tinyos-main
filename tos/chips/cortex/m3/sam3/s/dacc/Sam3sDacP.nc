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
#include "sam3spwmhardware.h"

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

    interface StdControl as PwmControl;
    interface Sam3sPwm as Pwm;
  }
}
implementation
{

  norace uint16_t currentLength;
  norace uint32_t *currentBuffer;
  norace uint16_t nextLength;
  norace uint32_t *nextBuffer;

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

      call Sam3sDac.stopPdc();
    }
    return SUCCESS;
  }

  command error_t StdControl.stop()
  {
    atomic
    {
      call DacClockControl.disable();
      call DacInterrupt.disable();
      call PwmControl.stop();
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

  command uint32_t Sam3sDac.setFrequency(uint32_t frequency)
  {
    uint32_t pwmFreq;

    dacc_mr_t mr = DACC->mr;

    if(frequency > 1000000)
    {
      // DAC doesn't support this
      return 0;
    }

    call PwmControl.start();

    pwmFreq = 1200; // set it at about 1 MHz

    if(call Pwm.configure(pwmFreq) != SUCCESS)
    {
      return 0;
    }
    // get the actual frequency
    pwmFreq = call Pwm.getFrequency();
    // now, calculate the period we really need
    call Pwm.setPeriod(pwmFreq * 1000 / frequency);

    call Pwm.enableCompare(PWM_COMPARE_DAC, 1);
    call Pwm.setEventCompares(PWM_EVENT_DAC, (1 << PWM_COMPARE_DAC));

    // setup the DAC to be triggered from external triggers
    mr.bits.trgen = 1;
    mr.bits.trgsel = 4 + PWM_EVENT_DAC; // select the right event

    DACC->mr = mr;

    return pwmFreq * 1000 / (pwmFreq * 1000 / frequency);
  }

  async command error_t Sam3sDac.setBuffer(uint32_t *buffer, uint16_t length)
  {
    if(call HplPdc.getTxCounter() == 0)
    {
      call HplPdc.setTxPtr(buffer);
      call HplPdc.setTxCounter(length);
      atomic
      {
        currentBuffer = buffer;
        currentLength = length;
      }
      call Sam3sDac.startPdc();
    } else 
    {
      if(call HplPdc.getNextTxCounter() == 0)
      {
        dacc_ier_t ier;
        ier.flat = 0;
        call HplPdc.setNextTxPtr(buffer);
        call HplPdc.setNextTxCounter(length);
        atomic
        {
          nextBuffer = buffer;
          nextLength = length;
          // enable endtx interrupt again
          ier.bits.endtx = 1;
          DACC->ier = ier;
        }
      } else {
        // PDC busy
        return EBUSY;
      }
    }
    return SUCCESS;
  }

  async command void Sam3sDac.startPdc()
  {
    dacc_ier_t ier;
    call DacInterrupt.disable();
    call DacInterrupt.clearPending();
    call DacInterrupt.enable();

    ier.flat = 0;
    ier.bits.endtx = 1;
    ier.bits.txbufe = 1;
    DACC->ier = ier;
    
    call HplPdc.enablePdcTx();

  }

  async command void Sam3sDac.stopPdc()
  {
    dacc_idr_t idr;
    call DacInterrupt.disable();

    idr.bits.endtx = 1;
    idr.bits.txbufe = 1;
    DACC->idr = idr;

    call HplPdc.disablePdcTx();
  }

  task void signalDone()
  {
    signal Sam3sDac.bufferDone(SUCCESS, currentBuffer, currentLength);
    atomic
    {
      currentBuffer = nextBuffer;
      currentLength = nextLength;
    }
  }


  void handler() @spontaneous()
  {
    dacc_isr_t isr = DACC->isr;
    dacc_idr_t idr;
    idr.flat = 0;

    if(isr.bits.txbufe)
    {
      // PDC done. Disable interrupts.
      idr.flat = 0;
      idr.bits.txbufe = 1;
      idr.bits.endtx = 1;
      call HplPdc.disablePdcTx();
      call Leds.led0Toggle();
      post signalDone();
    } else if(isr.bits.endtx)
    {
      // Disable endtx. If this was the second last buffer, txbufe will be the
      // next interrupt. Else the next set buffer will set this interrupt
      // again.
      idr.bits.endtx = 1; 
      call Leds.led1Toggle();

      post signalDone();
    } 

    DACC->idr = idr;

  }

  void DaccIrqHandler() @C() @spontaneous() 
  {
    call DacInterruptWrapper.preamble();
    handler();
    call DacInterruptWrapper.postamble();

  }

  default async event void Sam3sDac.bufferDone(error_t error, uint32_t *buffer, uint16_t length) { }

}

