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
 * $Date: 2007-04-05 13:45:09 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/**
 * Testing HAL of ADC12 on msp430. Switches three LEDs on, if successful.
 *
 * Author: Jan Hauer
 **/
generic module TestAdcC(uint8_t refVoltLevel)
{
  uses interface Boot;
  uses interface Resource;
  uses interface Msp430Adc12SingleChannel as SingleChannel;
  uses interface Leds;
  provides interface AdcConfigure<const msp430adc12_channel_config_t*>;

}
implementation
{

  // light sensor on eyesIFX platform - change this to whatever you need
  // (note that refVoltLevel is a parameter to this component)
  const msp430adc12_channel_config_t config = {
                      INPUT_CHANNEL_A2, REFERENCE_VREFplus_AVss, refVoltLevel,
                      SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_64_CYCLES,
                      SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1 };



#define BUFFER_SIZE 1000
  uint8_t counter = 0;
  uint8_t state = 0;
  uint16_t buffer[BUFFER_SIZE];
  void task getData();

  void assertData(uint16_t *data, uint16_t num)
  {
    uint16_t i;
    for (i=0; i<num; i++)
      if (!data[i] || data[i] == 0xFFFF)
        while(1)
          ;
  }

  event void Boot.booted()
  {
    post getData();
  }

  async command const msp430adc12_channel_config_t* AdcConfigure.getConfiguration()
  {
    return &config;
  }

  void task getData()
  {
    call Resource.request();
  }
  
  event void Resource.granted()
  {
    switch(state)
    {
      case 0: call Leds.led0On();
              state++;
              if (call SingleChannel.configureSingleRepeat(&config, 0) == SUCCESS)
                call SingleChannel.getData();
              break;
      case 1: call Leds.led0Off();
              call Leds.led1On();
              state++;
              if (call SingleChannel.configureSingle(&config) == SUCCESS)
                call SingleChannel.getData();
              break;
      case 2: call Leds.led0On();
              call Leds.led1On();
              state++;
              if (call SingleChannel.configureMultiple(&config, buffer, BUFFER_SIZE, 0) == SUCCESS)
                call SingleChannel.getData();
              break;
      case 3: call Leds.led0Off();
              call Leds.led1Off();
              call Leds.led2On();
              state++;
              if (call SingleChannel.configureMultipleRepeat(&config, buffer, 16, 0) == SUCCESS)
                call SingleChannel.getData();
              break;
      case 4: call Leds.led0On();
              call Leds.led1On();
              call Leds.led2On();
              call Resource.release();
              break;
    }
  }

  async event error_t SingleChannel.singleDataReady(uint16_t data)
  { 
    assertData(&data, 1);
    call Resource.release();
    post getData();
    return FAIL;
  }
  
    
  async event uint16_t* SingleChannel.multipleDataReady(uint16_t *buf, uint16_t length)
  {
    assertData(buf, length);
    call Resource.release();
    post getData();
    return 0;
  }
}

