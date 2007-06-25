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
 * $Revision: 1.2 $
 * $Date: 2007-06-25 15:43:37 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/**
 * Testing HAL of ADC12 on msp430. Switches three LEDs on, if the test was
 * successful.
 * 
 * Author: Jan Hauer
 */
#include "Msp430Adc12.h"
#include "evaluator.h"
configuration TestAdcAppC {
}
implementation
{
  // msp430 internal temperature sensor with ref volt from generator
#define CONFIG_VREF TEMPERATURE_DIODE_CHANNEL, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_2_5, SHT_SOURCE_ACLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES, SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1

  // msp430 internal temperature sensor with ref volt from AVcc
#define CONFIG_AVCC TEMPERATURE_DIODE_CHANNEL, REFERENCE_AVcc_AVss, REFVOLT_LEVEL_NONE, SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES, SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1
                        
  components MainC, LedsC, EvaluatorC;
  EvaluatorC.Leds -> LedsC;

  // Single, none
  components new TestAdcSingleC(CONFIG_AVCC) as TestSingle0,
             new Msp430Adc12ClientC() as Wrapper0;

  TestSingle0 -> MainC.Boot;
  TestSingle0.Resource -> Wrapper0;
  TestSingle0.SingleChannel -> Wrapper0.Msp430Adc12SingleChannel;
  EvaluatorC.Notify[unique(EVALUATOR_CLIENT)] -> TestSingle0;

  // Single, RefVolt
  components new TestAdcSingleC(CONFIG_VREF) as TestSingle1,
             new Msp430Adc12ClientAutoRVGC() as Wrapper1;

  TestSingle1 -> MainC.Boot;
  TestSingle1.Resource -> Wrapper1;
  TestSingle1.SingleChannel -> Wrapper1.Msp430Adc12SingleChannel;
  EvaluatorC.Notify[unique(EVALUATOR_CLIENT)] -> TestSingle1;
  Wrapper1.AdcConfigure -> TestSingle1;

  // Single, DMA
  components new TestAdcSingleC(CONFIG_AVCC) as TestSingle2,
             new Msp430Adc12ClientAutoDMAC() as Wrapper2;

  TestSingle2 -> MainC.Boot;
  TestSingle2.Resource -> Wrapper2;
  TestSingle2.SingleChannel -> Wrapper2.Msp430Adc12SingleChannel;
  EvaluatorC.Notify[unique(EVALUATOR_CLIENT)] -> TestSingle2;

  // Single, RefVolt + DMA
  components new TestAdcSingleC(CONFIG_VREF) as TestSingle3,
             new Msp430Adc12ClientAutoDMA_RVGC() as Wrapper3;

  TestSingle3 -> MainC.Boot;
  TestSingle3.Resource -> Wrapper3;
  TestSingle3.SingleChannel -> Wrapper3.Msp430Adc12SingleChannel;
  EvaluatorC.Notify[unique(EVALUATOR_CLIENT)] -> TestSingle3;
  Wrapper3.AdcConfigure -> TestSingle3;

  // Multi, none
  components new TestAdcMultiC(CONFIG_AVCC,
                     SUPPLY_VOLTAGE_HALF_CHANNEL, REFERENCE_AVcc_AVss) as TestMulti1,
             new Msp430Adc12ClientC() as Wrapper4;

  TestMulti1 -> MainC.Boot;
  TestMulti1.Resource -> Wrapper4;
  TestMulti1.MultiChannel -> Wrapper4.Msp430Adc12MultiChannel;
  EvaluatorC.Notify[unique(EVALUATOR_CLIENT)] -> TestMulti1;

  // Multi, RefVolt
  components new TestAdcMultiC(CONFIG_VREF,
                      SUPPLY_VOLTAGE_HALF_CHANNEL, REFERENCE_VREFplus_AVss) as TestMulti2,
             new Msp430Adc12ClientAutoRVGC() as Wrapper5;

  TestMulti2 -> MainC.Boot;
  TestMulti2.Resource -> Wrapper5;
  TestMulti2.MultiChannel -> Wrapper5.Msp430Adc12MultiChannel;
  EvaluatorC.Notify[unique(EVALUATOR_CLIENT)] -> TestMulti2;
  Wrapper5.AdcConfigure -> TestMulti2;

}

