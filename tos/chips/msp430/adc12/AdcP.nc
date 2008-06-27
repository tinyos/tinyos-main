/*
 * Copyright (c) 2006, Technische Universitaet Berlin
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
 * $Revision: 1.8 $
 * $Date: 2008-06-27 18:05:23 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

module AdcP @safe() {
  provides {
    interface Read<uint16_t> as Read[uint8_t client];
    interface ReadNow<uint16_t> as ReadNow[uint8_t client];
    interface Resource as ResourceReadNow[uint8_t client];
  }
  uses {
    // for Read only:
    interface Resource as ResourceRead[uint8_t client];
    // for ReadNow only:
    interface Resource as SubResourceReadNow[uint8_t client];
    // for Read and ReadNow:
    interface AdcConfigure<const msp430adc12_channel_config_t*> as Config[uint8_t client];
    interface Msp430Adc12SingleChannel as SingleChannel[uint8_t client];
  }
}
implementation
{
  enum {
    STATE_READ,
    STATE_READNOW,
    STATE_READNOW_INVALID_CONFIG,
  };
  
  // Resource interface / arbiter makes norace declaration safe
  norace uint8_t state;
  norace uint8_t owner;
  norace uint16_t value;

  error_t configure(uint8_t client)
  {
    error_t result = EINVAL;
    const msp430adc12_channel_config_t * ONE config;
    config = call Config.getConfiguration[client]();
    if (config->inch != INPUT_CHANNEL_NONE)
      result = call SingleChannel.configureSingle[client](config);
    return result;
  }

  command error_t Read.read[uint8_t client]()
  {
    return call ResourceRead.request[client]();
  }

  event void ResourceRead.granted[uint8_t client]() 
  {
    // signalled only for Read.read()
    error_t result = configure(client);
    if (result == SUCCESS){
      state = STATE_READ;
      result = call SingleChannel.getData[client]();
    } else {
      call ResourceRead.release[client]();
      signal Read.readDone[client](result, 0);
    }
  }
  
  async command error_t ResourceReadNow.request[uint8_t nowClient]()
  {
    return call SubResourceReadNow.request[nowClient]();
  }

  event void SubResourceReadNow.granted[uint8_t nowClient]()
  {
    if (configure(nowClient) == SUCCESS)
      state = STATE_READNOW;
    else
      state = STATE_READNOW_INVALID_CONFIG;
    signal ResourceReadNow.granted[nowClient]();
  }

  async command error_t ResourceReadNow.immediateRequest[uint8_t nowClient]()
  {
    error_t result = call SubResourceReadNow.immediateRequest[nowClient]();
    if (result == SUCCESS){
      result = configure(nowClient);
      if (result == SUCCESS)
        state = STATE_READNOW;
    }
    return result;
  }

  async command error_t ResourceReadNow.release[uint8_t nowClient]()
  {
    return call SubResourceReadNow.release[nowClient]();
  }

  async command bool ResourceReadNow.isOwner[uint8_t nowClient]()
  {
    return call SubResourceReadNow.isOwner[nowClient]();
  }
    
  async command error_t ReadNow.read[uint8_t nowClient]()
  {
    if (state == STATE_READNOW_INVALID_CONFIG)
      return EINVAL;
    else
      return call SingleChannel.getData[nowClient]();
  }
  
  void task readDone()
  {
    call ResourceRead.release[owner]();
    signal Read.readDone[owner](SUCCESS, value);
  }

  async event error_t SingleChannel.singleDataReady[uint8_t client](uint16_t data)
  {
    switch (state)
    {
      case STATE_READ:
        owner = client;
        value = data;
        post readDone();
        break;
      case STATE_READNOW:
        signal ReadNow.readDone[client](SUCCESS, data);
        break;
      default:
        // error !
        break;
    }
    return SUCCESS;
  }

  async event uint16_t* SingleChannel.multipleDataReady[uint8_t client](
      uint16_t *buf, uint16_t numSamples)
  {
    // error !
    return 0;
  }

  default async command error_t ResourceRead.request[uint8_t client]() { return FAIL; }
  default async command error_t ResourceRead.immediateRequest[uint8_t client]() { return FAIL; }
  default async command error_t ResourceRead.release[uint8_t client]() { return FAIL; }
  default async command bool ResourceRead.isOwner[uint8_t client]() { return FALSE; }
  default event void Read.readDone[uint8_t client]( error_t result, uint16_t val ){}

  default async command error_t SubResourceReadNow.release[uint8_t nowClient](){ return FAIL;}
  default async command error_t SubResourceReadNow.request[uint8_t nowClient](){ return FAIL; }
  default async command bool SubResourceReadNow.isOwner[uint8_t client]() { return FALSE; }
  default event void ResourceReadNow.granted[uint8_t nowClient](){}
  default async event void ReadNow.readDone[uint8_t client]( error_t result, uint16_t val ){}
  default async command error_t SubResourceReadNow.immediateRequest[uint8_t nowClient]() { return FAIL; }
  default async command error_t SingleChannel.getData[uint8_t client]()
  {
    return EINVAL;
  }

  const msp430adc12_channel_config_t defaultConfig = {INPUT_CHANNEL_NONE,0,0,0,0,0,0,0}; 
  default async command const msp430adc12_channel_config_t*
    Config.getConfiguration[uint8_t client]()
  { 
    return &defaultConfig;
  }  
  default async command error_t SingleChannel.configureSingle[uint8_t client](
      const msp430adc12_channel_config_t *config){ return FAIL; }
  
} 
