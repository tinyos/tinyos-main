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
 * $Date: 2007-06-25 15:43:37 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/**
 * Testing SingleChannel HAL interface of ADC12 on msp430. 
 *
 * Author: Jan Hauer
 **/
generic module TestAdcSingleC(  
                          uint8_t inch,            // input channel 
                          uint8_t sref,            // reference voltage 
                          uint8_t ref2_5v,         // reference voltage level 
                          uint8_t adc12ssel,       // clock source sample-hold-time 
                          uint8_t adc12div,        // clock divider sample-hold-time 
                          uint8_t sht,             // sample-hold-time
                          uint8_t sampcon_ssel,    // clock source sampcon signal 
                          uint8_t sampcon_id       // clock divider sampcon 
)
{
  uses {
    interface Boot;
    interface Resource;
    interface Msp430Adc12SingleChannel as SingleChannel;
  }
  provides {
    interface AdcConfigure<const msp430adc12_channel_config_t*>;
    interface Notify<bool>;
  }
}
implementation
{
#define BUFFER_SIZE 100
  const msp430adc12_channel_config_t config = {inch, sref, ref2_5v, adc12ssel, adc12div, sht, sampcon_ssel, sampcon_id};
  uint8_t state;
  uint16_t buffer[BUFFER_SIZE];
  void task getData();

  void task signalFailure()
  {
    signal Notify.notify(FALSE);
  }

  void assertData(uint16_t *data, uint16_t num)
  {
    uint16_t i;
    for (i=0; i<num; i++)
      if (!data[i] || data[i] >= 0xFFF)
        post signalFailure();
  }

  event void Boot.booted()
  {
    state = 0;
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
      case 0: state++;
              if (call SingleChannel.configureSingleRepeat(&config, 0) == SUCCESS)
                call SingleChannel.getData();
              break;
      case 1: state++;
              if (call SingleChannel.configureSingle(&config) == SUCCESS)
                call SingleChannel.getData();
              break;
      case 2: state++;
              if (call SingleChannel.configureMultiple(&config, buffer, BUFFER_SIZE, 0) == SUCCESS)
                call SingleChannel.getData();
              break;
      case 3: state++;
              if (call SingleChannel.configureMultipleRepeat(&config, buffer, 16, 0) == SUCCESS)
                call SingleChannel.getData();
              break;
      default: call Resource.release();
              signal Notify.notify(TRUE);
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

  command error_t Notify.enable(){}
  command error_t Notify.disable(){}
}

