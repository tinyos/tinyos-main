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
 * $Revision: 1.3 $
 * $Date: 2008-06-23 20:25:14 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/**
 * Testing MultiChannel HAL interface of ADC12 on msp430. 
 *
 * Author: Jan Hauer
 **/
generic module TestAdcMultiC(  
                          uint8_t inch,            // first input channel 
                          uint8_t sref,            // reference voltage 
                          uint8_t ref2_5v,         // reference voltage level 
                          uint8_t adc12ssel,       // clock source sample-hold-time 
                          uint8_t adc12div,        // clock divider sample-hold-time 
                          uint8_t sht,             // sample-hold-time
                          uint8_t sampcon_ssel,    // clock source sampcon signal 
                          uint8_t sampcon_id,      // clock divider sampcon 

                          uint8_t inch2,           // second input channel 
                          uint8_t sref2            // second reference voltage 
) @safe()
{
  uses {
    interface Boot;
    interface Resource;
    interface Msp430Adc12MultiChannel as MultiChannel;
  }
  provides {
    interface Notify<bool>;
    interface AdcConfigure<const msp430adc12_channel_config_t*>;
  }
}
implementation
{
  
#define BUFFER_SIZE 100
  const msp430adc12_channel_config_t config = {inch, sref, ref2_5v, adc12ssel, adc12div, sht, sampcon_ssel, sampcon_id};
  adc12memctl_t memCtl = {inch2, sref2};
  norace uint8_t state;
  uint16_t buffer[BUFFER_SIZE];
  void task getData();

  void task signalFailure()
  {
    signal Notify.notify(FALSE);
  }

  void task signalSuccess()
  {
    signal Notify.notify(TRUE);
  }

  bool assertData(uint16_t *data, uint16_t num)
  {
    uint16_t i;
    if (num != BUFFER_SIZE)
      post signalFailure();
    for (i=0; i<num; i++)
      if (!data[i] || data[i] >= 0xFFF){
        post signalFailure();
        return FALSE;
      }
    return TRUE;
  }

  async command const msp430adc12_channel_config_t* AdcConfigure.getConfiguration()
  {
    return &config;
  }

  event void Boot.booted()
  {
    state = 0;
    post getData();
  }

  void task getData()
  {
    call Resource.request();
  }
  
  event void Resource.granted()
  {
    if (call MultiChannel.configure(&config, &memCtl, 1, buffer, BUFFER_SIZE, 0) == SUCCESS)
      call MultiChannel.getData();
  }

  async event void MultiChannel.dataReady(uint16_t *buf, uint16_t numSamples)
  {
    if (assertData(buf, numSamples) && state++ == 0)
      post signalSuccess();
    else
      post signalFailure();
    call Resource.release();
  }

  command error_t Notify.enable(){}
  command error_t Notify.disable(){}
}

