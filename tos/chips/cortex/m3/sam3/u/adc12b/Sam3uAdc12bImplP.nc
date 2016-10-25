/*
 * Copyright (c) 2009 Johns Hopkins University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author JeongGil Ko
 */

#include "sam3uadc12bhardware.h"
module Sam3uAdc12bImplP
{
  provides {
    interface Init;
    interface Sam3uGetAdc12b as Sam3uAdc12b[uint8_t id];
  }

  uses {
    interface HplNVICInterruptCntl as ADC12BInterrupt;
    interface HplSam3GeneralIOPin as Adc12bPin;
    interface HplSam3PeripheralClockCntl as Adc12bClockControl;
    interface HplSam3Clock as ClockConfig;
    interface McuSleep;
#ifdef SAM3U_ADC12B_PDC
    interface HplSam3Pdc as HplPdc;
#endif
    interface Leds;
  }
}

implementation
{

  norace uint8_t clientID;

  norace uint8_t state;

  enum{
    S_ADC,
    S_IDLE,
  };

  command error_t Init.init(){

    /* Enable interrupts */
    call ADC12BInterrupt.configure(IRQ_PRIO_ADC12B); // Peripheral ID 26 for ADC12B
    call ADC12BInterrupt.enable();

    /* Enable clock */
    call Adc12bClockControl.enable();

    /* Set IO line */
    call Adc12bPin.disablePioControl(); // Disable whatever is set currently
    call Adc12bPin.selectPeripheralB(); // set to peripheral B

    state = S_IDLE;

    return SUCCESS;
  }

  async command error_t Sam3uAdc12b.configureAdc[uint8_t id](const sam3u_adc12_channel_config_t *config){

    // Since CHER is write-only read the information in CHSR in CHER format
    //volatile adc12b_cher_t *CHSR = (volatile adc12b_cher_t *) 0x400A8018;
    volatile adc12b_cher_t *CHER = (volatile adc12b_cher_t *) 0x400A8010;
    adc12b_cher_t cher;

    volatile adc12b_chdr_t *CHDR = (volatile adc12b_chdr_t *) 0x400A8014;
    adc12b_chdr_t chdr;

    // Since IER is write-only read the information in IMR in IER format
    //volatile adc12b_ier_t *IMR = (volatile adc12b_ier_t *) 0x400A802C;
    volatile adc12b_ier_t *IER =  (volatile adc12b_ier_t *) 0x400A8024;
    adc12b_ier_t ier;

    volatile adc12b_idr_t *IDR =  (volatile adc12b_idr_t *) 0x400A8028;
    adc12b_idr_t idr;

    // CR is write-only; There is no need to read it for modification but just set the memory location
    volatile adc12b_cr_t *CR = (volatile adc12b_cr_t *) 0x400A8000;
    adc12b_cr_t cr;

    // MR is read-write
    volatile adc12b_mr_t *MR = (volatile adc12b_mr_t *) 0x400A8004;
    adc12b_mr_t mr = *MR;

    // ACR is read-write
    volatile adc12b_acr_t *ACR = (volatile adc12b_acr_t *) 0x400A8064;
    adc12b_acr_t acr = *ACR;

    // EMR is read-write
    volatile adc12b_emr_t *EMR = (volatile adc12b_emr_t *) 0x400A8068;
    adc12b_emr_t emr = *EMR;

    cher.flat = 0;
    chdr.flat = 0x000000FF;
    *CHDR = chdr;
    idr.flat = 0x000000FF;
    *IDR = idr;

    switch(config->channel) {
    case 0:
      cher.bits.ch0 = 1;
      ier.bits.eoc0 = 1;
      break;
    case 1:
      cher.bits.ch1 = 1;
      ier.bits.eoc1 = 1;
      break;
    case 2:
      cher.bits.ch2 = 1;
      ier.bits.eoc2 = 1;
      break;
    case 3:
      cher.bits.ch3 = 1;
      ier.bits.eoc3 = 1;
      break;
    case 4:
      cher.bits.ch4 = 1;
      ier.bits.eoc4 = 1;
      break;
    case 5:
      cher.bits.ch5 = 1;
      ier.bits.eoc5 = 1;
      break;
    case 6:
      cher.bits.ch6 = 1;
      ier.bits.eoc6 = 1;
      break;
    case 7:
      cher.bits.ch7 = 1;
      ier.bits.eoc7 = 1;
      break;
    default:
      // Just return FAIL?
      cher.bits.ch0 = 0;
      ier.bits.eoc0 = 0;
      break;
    }

    cr.bits.swrst = 0;
    cr.bits.start = 0; // disable start bit for the configuration stage

    mr.bits.prescal = config->prescal;
    mr.bits.shtim = config->shtim;
    mr.bits.lowres = config->lowres;
    mr.bits.trgen = config->trgen;
    mr.bits.trgsel = config->trgsel;
    mr.bits.sleep = config->sleep;
    mr.bits.startup = config->startup;

    acr.bits.ibctl = config->ibctl;
    acr.bits.gain = 0;
    acr.bits.diff = config->diff;
    acr.bits.offset = 0;

    emr.bits.offmodes = 0;
    emr.bits.off_mode_startup_time = config->startup;

    // We have now locally modified all the register values
    // Write the register back in its respective memory space
    *CHER = cher;
    *IER = ier;
    *CR = cr;
    *MR = mr;
    *ACR = acr;
    *EMR = emr;

    return SUCCESS;
  }

  async command error_t Sam3uAdc12b.getData[uint8_t id](){
    // CR is write-only; There is no need to read it for modification but just set the memory location
    volatile adc12b_cr_t *CR = (volatile adc12b_cr_t *) 0x400A8000;
    adc12b_cr_t cr;

    call Adc12bClockControl.enable();

    atomic clientID = id;
    if(state != S_IDLE){
      return EBUSY;
    }else{
      atomic {
	state = S_ADC;
      }
      cr.bits.start = 1; // enable software trigger
      *CR = cr;
      call ADC12BInterrupt.enable();
      return SUCCESS;
    }
  }

  async event void ClockConfig.mainClockChanged(){}

  /* Get events (signals) from chips here! */
  void handler() @spontaneous() {

    // CR is write-only; There is no need to read it for modification but just set the memory location
    volatile adc12b_cr_t *CR = (volatile adc12b_cr_t *) 0x400A8000;
    adc12b_cr_t cr;

    // Read SR
    volatile adc12b_sr_t *SR = (volatile adc12b_sr_t *) 0x400A801C;
    adc12b_sr_t sr = *SR;

    uint16_t data = 0;

#ifndef SAM3U_ADC12B_PDC
    // Read LCDR
    volatile adc12b_lcdr_t *LCDR = (volatile adc12b_lcdr_t *) 0x400A8020;
    adc12b_lcdr_t lcdr = *LCDR;
    call Adc12bClockControl.disable();
    if(sr.bits.drdy){
      atomic {
	data = lcdr.bits.ldata;
	cr.bits.start = 0; // disable software trigger
	*CR = cr;
	//get data from register
	state = S_IDLE;
      }
      signal Sam3uAdc12b.dataReady[clientID](data);
    }
#else
    if(sr.bits.endrx){
      atomic state = S_IDLE;
      atomic cr.bits.start = 0; // enable software trigger
      atomic *CR = cr;
      signal Sam3uAdc12b.dataReady[clientID](data);
    }else{
      call HplPdc.enablePdcRx();
      atomic cr.bits.start = 1; // enable software trigger
      atomic *CR = cr;        
    }
#endif
  }
  void Adc12BIrqHandler() @C() @spontaneous() {
    call McuSleep.irq_preamble();
    call ADC12BInterrupt.disable();
    handler();
    call McuSleep.irq_postamble();
  }


  /* Default functions */
 default async event error_t Sam3uAdc12b.dataReady[uint8_t id](uint16_t data){
   return SUCCESS;
 }

}
