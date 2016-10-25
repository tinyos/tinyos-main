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
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Thomas Schmid
 */

#include "sam3sadchardware.h"
module Sam3sAdcImplP
{
  provides {
    interface Init;
    interface Sam3sGetAdc as Sam3sAdc[uint8_t id];
  }

  uses {
    interface HplNVICInterruptCntl as ADCInterrupt;
    interface HplSam3GeneralIOPin as AdcPin;
    interface HplSam3PeripheralClockCntl as AdcClockControl;
    interface HplSam3Clock as ClockConfig;
    interface McuSleep;
#ifdef SAM3S_ADC_PDC
    interface HplSam3Pdc as HplPdc;
#endif
    interface Leds;
  }
}

implementation
{

  norace uint8_t clientID;

  norace uint8_t state;

  norace uint8_t channel;

  enum{
    S_ADC,
    S_IDLE,
  };

  command error_t Init.init(){

    /* Enable clock */
    call AdcClockControl.enable();

    ADC->idr.flat = 0x1f00ffff; // disable all interrupt sources
    ADC->idr.flat = 0x1f00ffff; // disable all interrupt sources

    /* Reset ADC */
    ADC->cr.flat = 0x1;

    /* Configure interrupts */
    call ADCInterrupt.configure(IRQ_PRIO_ADC);

    /* Set IO line */
    call AdcPin.disablePioControl(); // Disable whatever is set currently
    call AdcPin.selectPeripheralD(); // set to peripheral D. All ADC pins are on D

    state = S_IDLE;

    return SUCCESS;
  }

  async command error_t Sam3sAdc.configureAdc[uint8_t id](const sam3s_adc_channel_config_t *config){

    adc_chdr_t chdr;
    adc_idr_t idr;
    adc_cr_t cr;
    adc_mr_t mr;
    adc_acr_t acr;
    adc_cgr_t cgr = ADC->cgr;
    adc_cor_t cor = ADC->cor;

    adc_cher_t cher;
    adc_ier_t ier;

    channel = config->channel;

    //cher.flat = ADC->chsr.flat; // read from status
    cher.flat = 0;
    //ier.flat = ADC->imr.flat;   // read from mask to see who is enabled
    ier.flat = 0;

    chdr.flat = 0x0000FFFF;
    ADC->chdr = chdr; // disable all channels during setup
    idr.flat = 0x1f00FFFF;
    ADC->idr = idr; // disable all interrupts during setup

    cher.flat |= (1 << config->channel);
#ifndef SAM3S_ADC_PDC 
    // enable channel interrupt
    ier.flat |= (1 << config->channel);
#else
    // enable PDC channel interrupt
    ier.bits.rxbuff = 1;
#endif

    cr.bits.swrst = 0;
    cr.bits.start = 0; // disable start bit for the configuration stage

    mr.bits.trgen    = config->trgen;
    mr.bits.trgsel   = config->trgsel  ;
    mr.bits.lowres   = config->lowres  ;
    mr.bits.sleep    = config->sleep   ;
    mr.bits.fwup     = config->fwup    ;
    mr.bits.freerun  = config->freerun ;
    mr.bits.prescal  = config->prescal ;
    mr.bits.startup  = config->startup ;
    mr.bits.settling = config->settling;
    mr.bits.anach    = config->anach   ;
    mr.bits.tracktim = config->tracktim;
    mr.bits.transfer = config->transfer;
    mr.bits.useq     = config->useq    ;

    acr.bits.ibctl   = config->ibctl;

    cgr.flat &= (3 << (config->channel << 1)); 
    cgr.flat |= (config->gain << (config->channel << 1));
    
    if(config->diff)
    {
        cor.flat |= ((1 << config->channel) << 16);
    } else {
        cor.flat &= ~ ((1 << config->channel) << 16);
    }
    if(config->offset)
    {
        cor.flat |= ((1 << config->channel));
    } else {
        cor.flat &= ~ (1 << config->channel);
    }

    call ADCInterrupt.enable();
    call ADCInterrupt.clearPending();

    // We have now locally modified all the register values
    // Write the register back in its respective memory space
    ADC->cher = cher;
    ADC->cr   = cr;
    ADC->mr   = mr;
    ADC->acr  = acr;
    ADC->cgr  = cgr;
    ADC->cor  = cor;

    ADC->ier  = ier;

    call Leds.led0Toggle();

    return SUCCESS;
  }

  async command error_t Sam3sAdc.getData[uint8_t id](){
    adc_cr_t cr;
    cr.flat = 0;

    call AdcClockControl.enable();
    //call ADCInterrupt.enable();
    //call ADCInterrupt.clearPending();

    atomic clientID = id;
    if(state != S_IDLE){
      return EBUSY;
    }else{
      cr.bits.start = 1; // enable software trigger
      ADC->cr = cr;
      atomic state = S_ADC;
      call Leds.led1Toggle();
      return SUCCESS;
    }
  }

  async event void ClockConfig.mainClockChanged(){}

  /* Get events (signals) from chips here! */
  void handler() @spontaneous() {
    adc_cr_t cr;
    adc_isr_t isr = ADC->isr;


    uint16_t data = 0;

    call Leds.led2Toggle();

#ifndef SAM3S_ADC_PDC
    call ADCInterrupt.disable();
    
    // read eoc for the current channel
    if(isr.flat & (1 << channel)){
      data = ADC->cdr[channel].bits.data;
      cr.bits.start = 0; // disable software trigger
      ADC->cr = cr;
      //get data from register
      atomic state = S_IDLE;
      call AdcClockControl.disable();
      signal Sam3sAdc.dataReady[clientID](data);
    }
#else
    if(isr.bits.rxbuff){
      //call ADCInterrupt.disable();
      atomic {
          state = S_IDLE;
          cr.bits.start = 0; // enable software trigger
          ADC->cr = cr;        
      }
      signal Sam3sAdc.dataReady[clientID](data);
    }else{
      call HplPdc.enablePdcRx();
      atomic 
      {
          cr.bits.start = 1; // enable software trigger
          ADC->cr = cr;        
      }
    }
#endif
  }

  void AdcIrqHandler() @C() @spontaneous() {
    call McuSleep.irq_preamble();
    handler();
    call McuSleep.irq_postamble();
  }


  /* Default functions */
 default async event error_t Sam3sAdc.dataReady[uint8_t id](uint16_t data){
   return SUCCESS;
 }

}
