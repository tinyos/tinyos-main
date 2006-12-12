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
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:23:06 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

module AdcP {
  provides {
    interface Read<uint16_t> as Read[uint8_t client];
    interface ReadNow<uint16_t> as ReadNow[uint8_t client];
    interface Resource as ResourceReadNow[uint8_t client];
    interface ReadStream<uint16_t> as ReadStream[uint8_t streamClient];
  }
  uses {
    // for Read only:
    interface Resource as ResourceRead[uint8_t client];
    // for ReadNow only:
    interface Resource as SubResourceReadNow[uint8_t client];
    // for Read and ReadNow:
    interface AdcConfigure<const msp430adc12_channel_config_t*> as Config[uint8_t client];
    interface Msp430Adc12SingleChannel as SingleChannel[uint8_t client];
    // for ReadStream only:
    interface AdcConfigure<const msp430adc12_channel_config_t*> as ConfigReadStream[uint8_t streamClient];
    interface Msp430Adc12SingleChannel as SingleChannelReadStream[uint8_t streamClient];
    interface Resource as ResourceReadStream[uint8_t streamClient];

  }
}
implementation
{
  enum {
    STATE_READ,
    STATE_READNOW,
    STATE_READNOW_INVALID_CONFIG,
    STATE_READSTREAM,
  };
  
  struct stream_entry_t {
    uint16_t count;
    struct stream_entry_t *next;
  };
  
  // Resource interface / arbiter makes norace declaration safe
  norace uint8_t state;
  norace uint8_t owner;
  norace uint16_t value;
  norace uint16_t *resultBuf; 

  // atomic section in postBuffer() makes norace safe
  norace struct stream_entry_t *streamBuf[uniqueCount(ADCC_READ_STREAM_SERVICE)];
  norace uint32_t usPeriod[uniqueCount(ADCC_READ_STREAM_SERVICE)];
  msp430adc12_channel_config_t streamConfig;
    
  void task finishStreamRequest();
  void task signalBufferDone();
  void nextReadStreamRequest(uint8_t streamClient);

  error_t configure(uint8_t client)
  {
    error_t result = EINVAL;
    const msp430adc12_channel_config_t *config;
    config = call Config.getConfiguration[client]();
    if (config->inch != INPUT_CHANNEL_NONE)
      result = call SingleChannel.configureSingle[client](config);
    return result;
  }

  command error_t Read.read[uint8_t client]()
  {
    if (call ResourceRead.isOwner[client]())
      return EBUSY;
    return call ResourceRead.request[client]();
  }

  event void ResourceRead.granted[uint8_t client]() 
  {
    // signalled only for Read.read()
    error_t result = configure(client);
    if (result == SUCCESS){
      state = STATE_READ;
      result = call SingleChannel.getData[client]();
    }
    if (result != SUCCESS){
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
      uint16_t *buf, uint16_t length)
  {
    // error !
    return 0;
  }
  
  command error_t ReadStream.postBuffer[uint8_t streamClient]( uint16_t* buf, uint16_t count )
  {
    struct stream_entry_t *newEntry = (struct stream_entry_t *) buf;
    
    newEntry->count = count;
    newEntry->next = 0;
    atomic {
      if (!streamBuf[streamClient])
        streamBuf[streamClient] = newEntry;
      else {
        struct stream_entry_t *tmp = streamBuf[streamClient];
        while (tmp->next)
          tmp = tmp->next;
        tmp->next = newEntry;
      }
    }
    return SUCCESS;
  }
  
  command error_t ReadStream.read[uint8_t streamClient]( uint32_t _usPeriod )
  {
    if (!streamBuf[streamClient])
      return EINVAL;
    if (call ResourceReadStream.isOwner[streamClient]())
      return EBUSY;
    usPeriod[streamClient] = _usPeriod;
    return call ResourceReadStream.request[streamClient]();
  }

  void task finishStreamRequest()
  {
    call ResourceReadStream.release[owner]();
    if (!streamBuf[owner])
      // all posted buffers were filled
      signal ReadStream.readDone[owner]( SUCCESS, usPeriod[owner] );
    else {
      // the commented code below makes gcc throw
      // "internal error: unsupported relocation error" !?!
      /*
      do {
        signal ReadStream.bufferDone[owner]( FAIL, (uint16_t *) streamBuf[owner], 0);
        streamBuf[owner] = streamBuf[owner]->next;
      } while (streamBuf[owner]);
      */
      signal ReadStream.readDone[owner]( FAIL, 0 );
    }
  }  

  event void ResourceReadStream.granted[uint8_t streamClient]() 
  {
    error_t result;
    const msp430adc12_channel_config_t *config;
    struct stream_entry_t *entry = streamBuf[streamClient];

    if (!entry)
      result = EINVAL;
    else {
      config = call ConfigReadStream.getConfiguration[streamClient]();
      if (config->inch == INPUT_CHANNEL_NONE)
        result = EINVAL;
      else {
        owner = streamClient;
        streamConfig = *config;
        streamConfig.sampcon_ssel = SAMPCON_SOURCE_SMCLK; // assumption: SMCLK runs at 1 MHz
        streamConfig.sampcon_id = SAMPCON_CLOCK_DIV_1; 
        streamBuf[streamClient] = entry->next;
        result = call SingleChannelReadStream.configureMultiple[streamClient](
            &streamConfig, (uint16_t *) entry, entry->count, usPeriod[streamClient]);
        if (result == SUCCESS)
          result = call SingleChannelReadStream.getData[streamClient]();
        else {
          streamBuf[streamClient] = entry;
          post finishStreamRequest();
          return;
        }
      }
    }
    if (result != SUCCESS){
      call ResourceReadStream.release[streamClient]();
      signal ReadStream.readDone[streamClient]( FAIL, 0 );
    }
    return;
  }


  async event uint16_t* SingleChannelReadStream.multipleDataReady[uint8_t streamClient](
      uint16_t *buf, uint16_t length)
  {
    error_t nextRequest;
    
    if (!resultBuf){
      value = length;
      resultBuf = buf;
      post signalBufferDone();
      if (!streamBuf[streamClient])
        post finishStreamRequest();
      else {
        // fill next buffer (this is the only async code dealing with buffers)
        struct stream_entry_t *entry = streamBuf[streamClient];
        streamBuf[streamClient] = streamBuf[streamClient]->next;
        nextRequest = call SingleChannelReadStream.configureMultiple[streamClient](
            &streamConfig, (uint16_t *) entry, entry->count, usPeriod[streamClient]);
        if (nextRequest == SUCCESS)
          nextRequest = call SingleChannelReadStream.getData[streamClient]();
        if (nextRequest != SUCCESS){
          streamBuf[owner] = entry;
          post finishStreamRequest();
        }
      }
    } else {
      // overflow: can't signal data fast enough
      struct stream_entry_t *entry = (struct stream_entry_t *) buf;
      entry->next = streamBuf[streamClient];
      streamBuf[streamClient] = entry; // what a waste
      post finishStreamRequest();
    }
    return 0;
  }

  void task signalBufferDone()
  {
    signal ReadStream.bufferDone[owner]( SUCCESS, resultBuf, value);
    resultBuf = 0;
  }
  
  async event error_t SingleChannelReadStream.singleDataReady[uint8_t streamClient](uint16_t data)
  {
    // won't happen
    return SUCCESS;
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
  default async command error_t SubResourceReadNow.immediateRequest[uint8_t nowClient]()
  { 
    return FAIL; 
  }
  
  default async command error_t ResourceReadStream.request[uint8_t streamClient]() { return FAIL; }
  default async command error_t ResourceReadStream.release[uint8_t streamClient]() { return FAIL; }
  default async command bool ResourceReadStream.isOwner[uint8_t streamClient]() { return FALSE; }
  default event void ReadStream.bufferDone[uint8_t streamClient]( error_t result, 
			 uint16_t* buf, uint16_t count ){}
  default event void ReadStream.readDone[uint8_t streamClient]( error_t result, uint32_t actualPeriod ){ } 

  default async command error_t SingleChannel.getData[uint8_t client]()
  {
    return EINVAL;
  }

  // will be placed in flash
  const msp430adc12_channel_config_t defaultConfig = {INPUT_CHANNEL_NONE,0,0,0,0,0,0,0}; 
  default async command const msp430adc12_channel_config_t*
    Config.getConfiguration[uint8_t client]()
  { 
    return &defaultConfig;
  }

  default async command const msp430adc12_channel_config_t*
    ConfigReadStream.getConfiguration[uint8_t client]()
  { 
    return &defaultConfig;
  }

  default async command error_t SingleChannelReadStream.configureMultiple[uint8_t client](
      const msp430adc12_channel_config_t *config, uint16_t buffer[], 
      uint16_t numSamples, uint16_t jiffies)
  {
    return FAIL;
  }

  default async command error_t SingleChannelReadStream.getData[uint8_t client]()
  {
    return FAIL;
  }

  default async command error_t SingleChannel.configureSingle[uint8_t client](
      const msp430adc12_channel_config_t *config){ return FAIL; }


}

