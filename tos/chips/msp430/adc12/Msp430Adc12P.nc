/*
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * $Revision: 1.2 $
 * $Date: 2006-07-12 17:01:40 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include <Msp430Adc12.h>
module Msp430Adc12P 
{
  provides {
    interface Init;
    interface Msp430Adc12SingleChannel as SingleChannel[uint8_t id];
    interface Msp430Adc12FastSingleChannel as FastSingleChannel[uint8_t id]; 
	}
	uses {
    interface ArbiterInfo as ADCArbiterInfo;
	  interface HplAdc12;
    interface Msp430Timer as TimerA;
    interface Msp430TimerControl as ControlA0;
    interface Msp430TimerControl as ControlA1;
    interface Msp430Compare as CompareA0;
    interface Msp430Compare as CompareA1;
    interface HplMsp430GeneralIO as Port60;
    interface HplMsp430GeneralIO as Port61;
    interface HplMsp430GeneralIO as Port62;
    interface HplMsp430GeneralIO as Port63;
    interface HplMsp430GeneralIO as Port64;
    interface HplMsp430GeneralIO as Port65;
    interface HplMsp430GeneralIO as Port66;
    interface HplMsp430GeneralIO as Port67;
    
	}
}
implementation
{ 
  enum { // conversionMode
    SINGLE_DATA,
    SINGLE_DATA_REPEAT,
    MULTIPLE_DATA,
    MULTIPLE_DATA_REPEAT,
  };
  enum { // flags
    ADC_BUSY = 1,               /* request pending */
    TIMERA_USED = 2,            /* TimerA used for SAMPCON signal */
    FAST_MODE = 4,
  };

  uint16_t *resultBuffer;        /* result buffer */
  uint16_t resultBufferLength;   /* length of buffer */
  uint16_t resultBufferIndex;    /* offset into buffer */
  norace uint8_t clientID;              /* ID of interface that issued current request */
  norace uint8_t flags;                 /* current state, see above */

  // norace is safe, because Resource interface resolves conflicts  
  norace uint8_t conversionMode; /* current conversion conversionMode, see above */

  command error_t Init.init()
  {
    call HplAdc12.disableConversion();
    call HplAdc12.adcOff();
    return SUCCESS;
  }
  
  error_t clientAccessRequest(uint8_t id)
  {
    atomic {
      if (call ADCArbiterInfo.userId() == id){
        if (flags & ADC_BUSY)
          return EBUSY;
        flags = ADC_BUSY;
        clientID = id;
        return SUCCESS;
      }
    }
    return ERESERVE;
  }

  inline void clientAccessFinished()
  {
    atomic flags = 0;
  }

  void prepareTimerA(uint16_t interval, uint16_t csSAMPCON, uint16_t cdSAMPCON)
  {
    msp430_compare_control_t ccResetSHI = {
      ccifg : 0, cov : 0, out : 0, cci : 0, ccie : 0,
      outmod : 0, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };

    call TimerA.setMode(MSP430TIMER_STOP_MODE);
    call TimerA.clear();
    call TimerA.disableEvents();
    call TimerA.setClockSource(csSAMPCON);
    call TimerA.setInputDivider(cdSAMPCON);
    call ControlA0.setControl(ccResetSHI);
    call CompareA0.setEvent(interval-1);
    call CompareA1.setEvent((interval-1)/2);
  }
    
  void startTimerA()
  {
    msp430_compare_control_t ccSetSHI = {
      ccifg : 0, cov : 0, out : 1, cci : 0, ccie : 0,
      outmod : 0, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };
    msp430_compare_control_t ccResetSHI = {
      ccifg : 0, cov : 0, out : 0, cci : 0, ccie : 0,
      outmod : 0, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };
    msp430_compare_control_t ccRSOutmod = {
      ccifg : 0, cov : 0, out : 0, cci : 0, ccie : 0,
      outmod : 7, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };
    // manually trigger first conversion, then switch to Reset/set conversionMode
    call ControlA1.setControl(ccResetSHI);
    call ControlA1.setControl(ccSetSHI);   
    //call ControlA1.setControl(ccResetSHI); 
    call ControlA1.setControl(ccRSOutmod);
    call TimerA.setMode(MSP430TIMER_UP_MODE); // go!
  }   
  
  void configureAdcPin( uint8_t inch )
  {
#ifdef P6PIN_AUTO_CONFIGURE
    switch (inch)
    {
      case 0: call Port60.selectModuleFunc(); call Port60.makeInput(); break;
      case 1: call Port61.selectModuleFunc(); call Port61.makeInput(); break;
      case 2: call Port62.selectModuleFunc(); call Port62.makeInput(); break;
      case 3: call Port63.selectModuleFunc(); call Port63.makeInput(); break;
      case 4: call Port64.selectModuleFunc(); call Port64.makeInput(); break;
      case 5: call Port65.selectModuleFunc(); call Port65.makeInput(); break;
      case 6: call Port66.selectModuleFunc(); call Port66.makeInput(); break;
      case 7: call Port67.selectModuleFunc(); call Port67.makeInput(); break;
    }
#endif
  }
  
  void resetAdcPin( uint8_t inch )
  {
#ifdef P6PIN_AUTO_CONFIGURE
    switch (inch)
    {
      case 0: call Port60.selectIOFunc(); break;
      case 1: call Port61.selectIOFunc(); break;
      case 2: call Port62.selectIOFunc(); break;
      case 3: call Port63.selectIOFunc(); break;
      case 4: call Port64.selectIOFunc(); break;
      case 5: call Port65.selectIOFunc(); break;
      case 6: call Port66.selectIOFunc(); break;
      case 7: call Port67.selectIOFunc(); break;
    }
#endif
  }
    
  void stopConversionSingleChannel()
  {
    adc12memctl_t memctl = call HplAdc12.getMCtl(0);
    if (flags & TIMERA_USED){
      call TimerA.setMode(MSP430TIMER_STOP_MODE);
    }
    resetAdcPin( memctl.inch );
    call HplAdc12.stopConversion();
    call HplAdc12.adcOff();
    call HplAdc12.setIEFlags(0);
    call HplAdc12.resetIFGs();
    clientAccessFinished();
  }

  error_t configureSingleData(uint8_t id, const msp430adc12_channel_config_t *config)
  {
    error_t result;
#ifdef CHECK_ARGS
    if (!config)
      return EINVAL;
#endif
    if ((result = clientAccessRequest(id)) == SUCCESS)
    {
      adc12ctl0_t ctl0 = { 
        adc12sc: 0,
        enc: 0,
        adc12tovie: 0,
        adc12ovie: 0,
        adc12on: 1,
        refon: call HplAdc12.getRefon(),
        r2_5v: call HplAdc12.isRef2_5V(),
        msc: 1,
        sht0: config->sht,
        sht1: config->sht
      };
      adc12ctl1_t ctl1 = {
        adc12busy: 0,
        conseq: 0,
        adc12ssel: config->adc12ssel,
        adc12div: config->adc12div,
        issh: 0,
        shp: 1,
        shs: 0,
        cstartadd: 0
      };
      adc12memctl_t memctl = {
        inch: config->inch,
        sref: config->sref,
        eos: 1
      };        
      conversionMode = SINGLE_DATA;
      configureAdcPin( config->inch );
      call HplAdc12.setCtl0(ctl0);
      call HplAdc12.setCtl1(ctl1);
      call HplAdc12.setMCtl(0, memctl);
      call HplAdc12.setIEFlags(0x01);
      //call HplAdc12.startConversion();
    }
    return result;
  }

  async command error_t SingleChannel.getSingleData[uint8_t id](
      const msp430adc12_channel_config_t *config)
  {
    error_t result = configureSingleData(id, config);
    if (result == SUCCESS)
      call HplAdc12.startConversion();
    return result;
  }

  async command error_t FastSingleChannel.configure[uint8_t id](const msp430adc12_channel_config_t *config)
  {
    return configureSingleData(id, config);
  }
  
  async command error_t FastSingleChannel.getSingleData[uint8_t id]()
  {
    if (clientID == id){
      flags |= FAST_MODE;
      call HplAdc12.startConversion();
      return SUCCESS;
    }
    return FAIL;
  }

  async command error_t SingleChannel.getSingleDataRepeat[uint8_t id](
      const msp430adc12_channel_config_t *config,
      uint16_t jiffies)
  {
    error_t result;
#ifdef CHECK_ARGS
    if (!config || jiffies == 1 || jiffies == 2)
      return EINVAL;
#endif
    if ((result = clientAccessRequest(id)) == SUCCESS)
    {
      adc12ctl0_t ctl0 = { 
        adc12sc: 0,
        enc: 0,
        adc12tovie: 0,
        adc12ovie: 0,
        adc12on: 1,
        refon: call HplAdc12.getRefon(),
        r2_5v: call HplAdc12.isRef2_5V(),
        msc: (jiffies == 0) ? 1 : 0,
        sht0: config->sht,
        sht1: config->sht
      };
      adc12ctl1_t ctl1 = {
        adc12busy: 0,
        conseq: 2,
        adc12ssel: config->adc12ssel,
        adc12div: config->adc12div,
        issh: 0,
        shp: 1,
        shs: (jiffies == 0) ? 0 : 1,
        cstartadd: 0
      };
      adc12memctl_t memctl = {
        inch: config->inch,
        sref: config->sref,
        eos: 1
      };        
      conversionMode = SINGLE_DATA_REPEAT;
      configureAdcPin( config->inch );
      call HplAdc12.setCtl0(ctl0);
      call HplAdc12.setCtl1(ctl1);
      call HplAdc12.setMCtl(0, memctl);
      call HplAdc12.setIEFlags(0x01);
      if (jiffies){
        atomic flags |= TIMERA_USED;   
        prepareTimerA(jiffies, config->sampcon_ssel, config->sampcon_id);
      }     
      call HplAdc12.startConversion();
      if (jiffies)
        startTimerA(); // go!
    }
    return result;
  }

  async command error_t SingleChannel.getMultipleData[uint8_t id](
      const msp430adc12_channel_config_t *config,
      uint16_t *buf, uint16_t length, uint16_t jiffies)
  {
    error_t result;
#ifdef CHECK_ARGS
    if (!config || !buf || !length || jiffies == 1 || jiffies == 2)
      return EINVAL;
#endif
    if ((result = clientAccessRequest(id)) == SUCCESS)
    {
      adc12ctl0_t ctl0 = { 
        adc12sc: 0,
        enc: 0,
        adc12tovie: 0,
        adc12ovie: 0,
        adc12on: 1,
        refon: call HplAdc12.getRefon(),
        r2_5v: call HplAdc12.isRef2_5V(),
        msc: (jiffies == 0) ? 1 : 0,
        sht0: config->sht,
        sht1: config->sht
      };
      adc12ctl1_t ctl1 = {
        adc12busy: 0,
        conseq: (length > 16) ? 3 : 1,
        adc12ssel: config->adc12ssel,
        adc12div: config->adc12div,
        issh: 0,
        shp: 1,
        shs: (jiffies == 0) ? 0 : 1,
        cstartadd: 0
      };
      adc12memctl_t memctl = {
        inch: config->inch,
        sref: config->sref,
        eos: 0
      };        
      uint16_t i, mask = 1;
      conversionMode = MULTIPLE_DATA;
      atomic {
        resultBuffer = buf;
        resultBufferLength = length;
        resultBufferIndex = 0;
      }    
      configureAdcPin( config->inch );
      call HplAdc12.setCtl0(ctl0);
      call HplAdc12.setCtl1(ctl1);
      for (i=0; i<(length-1) && i < 15; i++)
        call HplAdc12.setMCtl(i, memctl);
      memctl.eos = 1;  
      call HplAdc12.setMCtl(i, memctl);
      call HplAdc12.setIEFlags(mask << i);        
      
      if (jiffies){
        atomic flags |= TIMERA_USED;
        prepareTimerA(jiffies, config->sampcon_ssel, config->sampcon_id);
      }      
      call HplAdc12.startConversion();
      if (jiffies)
        startTimerA(); // go!
    }
    return result;
  }

  async command error_t SingleChannel.getMultipleDataRepeat[uint8_t id](
      const msp430adc12_channel_config_t *config,
      uint16_t *buf, uint8_t length, uint16_t jiffies)
  {
    error_t result;
#ifdef CHECK_ARGS
    if (!config || !buf || !length || length > 16 || jiffies == 1 || jiffies == 2)
      return EINVAL;
#endif
    if ((result = clientAccessRequest(id)) == SUCCESS)
    {
      adc12ctl0_t ctl0 = { 
        adc12sc: 0,
        enc: 0,
        adc12tovie: 0,
        adc12ovie: 0,
        adc12on: 1,
        refon: call HplAdc12.getRefon(),
        r2_5v: call HplAdc12.isRef2_5V(),
        msc: (jiffies == 0) ? 1 : 0,
        sht0: config->sht,
        sht1: config->sht
      };
      adc12ctl1_t ctl1 = {
        adc12busy: 0,
        ctl1.conseq = 3,
        adc12ssel: config->adc12ssel,
        adc12div: config->adc12div,
        issh: 0,
        shp: 1,
        shs: (jiffies == 0) ? 0 : 1,
        cstartadd: 0
      };
      adc12memctl_t memctl = {
        inch: config->inch,
        sref: config->sref,
        eos: 0
      };        
      uint16_t i, mask = 1;
      conversionMode = MULTIPLE_DATA_REPEAT;
      atomic { 
        resultBuffer = buf;
        resultBufferLength = length;
        resultBufferIndex = 0;            
      }
      configureAdcPin( config->inch );
      call HplAdc12.setCtl0(ctl0);
      call HplAdc12.setCtl1(ctl1);
      for (i=0; i<(length-1) && i < 15; i++)
        call HplAdc12.setMCtl(i, memctl);
      memctl.eos = 1;  
      call HplAdc12.setMCtl(i, memctl);
      call HplAdc12.setIEFlags(mask << i);        
      
      if (jiffies){
        atomic flags |= TIMERA_USED;
        prepareTimerA(jiffies, config->sampcon_ssel, config->sampcon_id);
      }      
      call HplAdc12.startConversion();
      if (jiffies)
        startTimerA(); // go!
    }
    return result;
  }

  async event void TimerA.overflow(){}
  async event void CompareA0.fired(){}
  async event void CompareA1.fired(){}

  
  async event void HplAdc12.conversionDone(uint16_t iv)
  {
    switch (conversionMode) 
    { 
      case SINGLE_DATA:
        if (flags & FAST_MODE){
#ifdef P6PIN_AUTO_CONFIGURE
          adc12memctl_t memctl = call HplAdc12.getMCtl(0);
          resetAdcPin( memctl.inch );
#endif
          clientAccessFinished();
          // stopConversionSingleChannel()
          signal FastSingleChannel.singleDataReady[clientID](call HplAdc12.getMem(0));
        } else {
          stopConversionSingleChannel();
          signal SingleChannel.singleDataReady[clientID](call HplAdc12.getMem(0));
        }
        break;
      case SINGLE_DATA_REPEAT:
        {
          error_t repeatContinue;
          repeatContinue = signal SingleChannel.singleDataReady[clientID](
                call HplAdc12.getMem(0));
          if (repeatContinue == FAIL)
            stopConversionSingleChannel();
          break;
        }
      case MULTIPLE_DATA:
        {
          uint16_t i = 0, length;
          if (resultBufferLength - resultBufferIndex > 16) 
            length = 16;
          else
            length = resultBufferLength - resultBufferIndex;
          do {
            *resultBuffer++ = call HplAdc12.getMem(i);
          } while (++i < length);
          resultBufferIndex += length;
              
          if (resultBufferLength - resultBufferIndex > 15)
            return;
          else if (resultBufferLength - resultBufferIndex > 0){
            adc12memctl_t memctl = call HplAdc12.getMCtl(0);
            memctl.eos = 1;
            call HplAdc12.setMCtl(resultBufferLength - resultBufferIndex, memctl);
          } else {
            stopConversionSingleChannel();
            signal SingleChannel.multipleDataReady[clientID](
                resultBuffer - resultBufferLength, resultBufferLength);
          }
        }
        break;
      case MULTIPLE_DATA_REPEAT:
        {
          uint8_t i = 0;
          do {
            *resultBuffer++ = call HplAdc12.getMem(i);
          } while (++i < resultBufferLength);
          
          resultBuffer = signal SingleChannel.multipleDataReady[clientID](
              resultBuffer-resultBufferLength,
                    resultBufferLength);
          if (!resultBuffer)  
            stopConversionSingleChannel();
          break;
        }
      } // switch
  }

  default async event error_t SingleChannel.singleDataReady[uint8_t id](uint16_t data)
  {
    return FAIL;
  }
  
  default async event void FastSingleChannel.singleDataReady[uint8_t id](uint16_t data)
  {
    return;
  }
  
  default async event uint16_t* SingleChannel.multipleDataReady[uint8_t id](
      uint16_t *buf, uint16_t length)
  {
    return 0;
  }
  
  async event void HplAdc12.memOverflow(){}
  async event void HplAdc12.conversionTimeOverflow(){}

}

