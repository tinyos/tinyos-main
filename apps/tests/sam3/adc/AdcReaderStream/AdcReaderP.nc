/*
 * Copyright (c) 2009 Johns Hopkins University.
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
 * ADC configuration settings (part of test application) for SAM3U's 12 bit ADC
 * @author JeongGil Ko
 */

#include "sam3sadchardware.h"

module AdcReaderP
{
  provides interface AdcConfigure<const sam3s_adc_channel_config_t*>;
}

implementation {
      const sam3s_adc_channel_config_t config = 
      {
         channel  : 5,
         trgen    : 0, // 0: trigger disabled
         trgsel   : 0, // 0: external trigger
         lowres   : 0, // 0: 12-bit
         sleep    : 0, // 0: normal, adc core and vref are kept on between conversions
         fwup     : 0, // 0: normal, sleep mode is defined by sleep bit
         freerun  : 0, // 0: normal mode, wait for trigger
         prescal  : 2, // ADCClock = MCK / ((prescal + 1)*2)
         startup  : 7, // 112 periods of ADCClock
         settling : 1, // 5 periods of ADCClock
         anach    : 0, // 0: no analog changed on channel switching
         tracktim : 1, // Tracking Time = (tracktim + 1) * ADCClock periods
         transfer : 1, // Transfer Period = (transfer*1+3) * ADCClock periods
         useq     : 0, // 0: normal, converts channel in sequence
         ibctl    : 1,
         diff     : 0,
         gain     : 0,
         offset   : 0,
      };

  async command const sam3s_adc_channel_config_t* AdcConfigure.getConfiguration() {
    return &config;
  }
}
