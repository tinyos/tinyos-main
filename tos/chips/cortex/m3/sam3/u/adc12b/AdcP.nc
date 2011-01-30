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

module AdcP {
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
    interface Sam3uGetAdc12b as GetAdc[uint8_t client];
    interface AdcConfigure<const sam3u_adc12_channel_config_t*> as Config[uint8_t client];
  }
}

implementation
{

  norace uint8_t state;
  norace uint8_t readNowClient;
  norace uint8_t setClient;
  norace uint16_t adcResult;

  enum {
    S_READ,
    S_READNOW,
  };

  error_t configureAdcRegisters(uint8_t client)
  {
    const sam3u_adc12_channel_config_t * ONE config;
    config = call Config.getConfiguration[client]();
    return call GetAdc.configureAdc[client](config);
  }

  /** Read.read - TEP 114 **/
  command error_t Read.read[uint8_t client]()
  {
    state = S_READ;
    return call ResourceRead.request[client]();
  }

  event void ResourceRead.granted[uint8_t client]() 
  {

    error_t result = configureAdcRegisters(client);

    if(result == SUCCESS){
      //call actual read!
      call GetAdc.getData[client]();
    }else{
      //configure failed!
      call ResourceRead.release[client]();
      signal Read.readDone[client](result, 0);
    }
  }

  /************************************************/

  /** ReadNow.read **/    
  async command error_t ReadNow.read[uint8_t nowClient]()
  {
    if(call SubResourceReadNow.isOwner[nowClient]()){
      return call GetAdc.getData[nowClient]();
    }else{
      return FAIL;
    }
  }

  task void signalGranted(){
    error_t error =  configureAdcRegisters(readNowClient);
    if(error == SUCCESS){
      state = S_READNOW;
    }else{
      // config error
    }
    signal ResourceReadNow.granted[readNowClient]();    
  }

  async command error_t ResourceReadNow.request[uint8_t nowClient]()
  {
    if(!call SubResourceReadNow.isOwner[nowClient]())
      return call SubResourceReadNow.request[nowClient]();
    else{
      atomic readNowClient = nowClient;
      post signalGranted();
      return SUCCESS;
    }
  }

  event void SubResourceReadNow.granted[uint8_t nowClient]()
  {
    error_t error =  configureAdcRegisters(nowClient);
    if(error == SUCCESS){
      state = S_READNOW;
    }else{
      // config error
    }
    signal ResourceReadNow.granted[nowClient]();
  }

  async command error_t ResourceReadNow.immediateRequest[uint8_t nowClient]()
  {
    error_t result = call SubResourceReadNow.immediateRequest[nowClient]();
    if (result == SUCCESS){
      result = configureAdcRegisters(nowClient);
      if (result == SUCCESS)
        state = S_READNOW;
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

  /** Read Done **/
  void task readDone()
  {
    call ResourceRead.release[setClient]();
    signal Read.readDone[setClient](SUCCESS, adcResult);
  }

  void task readDoneNow()
  {
    signal ReadNow.readDone[setClient](SUCCESS, adcResult);
  }

  /************************************************/

  /** Data is ready! **/
  async event error_t GetAdc.dataReady[uint8_t client](uint16_t data)
  {
    atomic setClient = client;
    atomic adcResult = data;

    switch (state)
    {
    case S_READ:
      call ResourceRead.release[client]();
      post readDone();
      break;
    case S_READNOW:
      post readDoneNow();
      break;
    default:
      break;
    }
    return SUCCESS;
  }
  /************************************************/

  const sam3u_adc12_channel_config_t defaultConfig = {
    channel: 0,
    diff: 0,
    prescal: 2,
    lowres: 0,
    shtim: 15,
    ibctl: 1,
    sleep: 0,
    startup: 104,
    trgen: 0,
    trgsel: 0
  };

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
 default async command error_t GetAdc.getData[uint8_t client](){ return EINVAL; }
  
 default async command const sam3u_adc12_channel_config_t*
 Config.getConfiguration[uint8_t client]()
  { 
    return &defaultConfig;
  }  
  
 default async command error_t GetAdc.configureAdc[uint8_t client](const sam3u_adc12_channel_config_t *config){ return FAIL; }

}
