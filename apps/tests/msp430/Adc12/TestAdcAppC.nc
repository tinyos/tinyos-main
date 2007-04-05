/* 
 * Copyright (c) 2007, Technische Universitaet Berlin
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
 * $Revision: 1.1 $
 * $Date: 2007-04-05 13:45:08 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/**
 * Testing HAL of ADC12 on msp430. Switches three LEDs on, if successful.
 * 
 * Author: Jan Hauer
 */
#include "Msp430Adc12.h"
configuration TestAdcAppC {
}
implementation
{
  components MainC,
             new TestAdcC(REFVOLT_LEVEL_1_5) as TestAdcC1,
             new Msp430Adc12ClientAutoRVGC() as Wrapper1,
             LedsC;

  TestAdcC1 -> MainC.Boot;
  TestAdcC1.Leds -> LedsC;
  TestAdcC1.Resource -> Wrapper1;
  TestAdcC1.SingleChannel -> Wrapper1.Msp430Adc12SingleChannel;
  Wrapper1.AdcConfigure -> TestAdcC1;

  components new TestAdcC(REFVOLT_LEVEL_2_5) as TestAdcC2,
             new Msp430Adc12ClientAutoRVGC() as Wrapper2;

  TestAdcC2 -> MainC.Boot;
  TestAdcC2.Leds -> LedsC;
  TestAdcC2.Resource -> Wrapper2;
  TestAdcC2.SingleChannel -> Wrapper2.Msp430Adc12SingleChannel;
  Wrapper2.AdcConfigure -> TestAdcC2;
}

