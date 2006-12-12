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
 * $Revision: 1.3 $
 * $Date: 2006-12-12 18:23:06 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * This component represents the HAL2 of the MSP430 ADC12
 * subsystem. Clients SHOULD NOT wire to <code>AdcC</code> directly but should
 * go via <code>AdcReadClientC</code>, <code>AdcReadNowClientC</code> or
 * <code>AdcReadStreamClientC</code>.
 *
 * @author Jan Hauer
 * @see  Please refer to TEP 101 for more information about this component and its
 *          intended use.
 */

module AdcC {
  provides {
    interface Read<uint16_t> as Read[uint8_t client];
    interface ReadNow<uint16_t> as ReadNow[uint8_t client];
    interface ReadStream<uint16_t> as ReadStream[uint8_t rsClient];
  }
  uses {
    // for Read only:
    interface Resource as Resource[uint8_t client];
    // for Read and ReadNow:
    interface Msp430Adc12Config as Config[uint8_t client];
    interface Msp430Adc12SingleChannel as SingleChannel[uint8_t client];
    // for ReadStream only:
    interface Msp430Adc12Config as ConfigReadStream[uint8_t rsClient];
    interface Msp430Adc12SingleChannel as SingleChannelReadStream[uint8_t rsClient];
    interface Resource as ResourceReadStream[uint8_t rsClient];
  }
}
implementation
{
  struct list_entry_t {
    uint16_t count;
    struct list_entry_t *next;
  };
  
  // Resource interface makes norace declaration safe
  norace bool readSync;
  norace uint8_t owner;
  norace uint16_t value;
  norace uint16_t *resultBuf; 
  // atomic section in postBuffer() makes norace safe
  norace struct list_entry_t *streamBuf[uniqueCount(ADCC_READ_STREAM_SERVICE)];
  norace uint32_t usPeriod[uniqueCount(ADCC_READ_STREAM_SERVICE)];
  msp430adc12_channel_config_t streamSettings;
    
  void task finishStreamRequest();
  void task signalBufferDone();
  void nextReadStreamRequest(uint8_t rsClient);
  
  command error_t Read.read[uint8_t client]()
  {
    return call Resource.request[client]();
  }
  
  async command error_t ReadNow.read[uint8_t client]()
  {
    msp430adc12_channel_config_t settings;
    error_t hal1request;
    
    settings = call Config.getChannelSettings[client]();
    if (settings.inch == INPUT_CHANNEL_NONE)
      return EINVAL; // Config not wired ?!
    
    // There is no automatic Resource reservation for ReadNow, 
    // but getSingleData() will fail if the client has not
    // reserved, because HAL1 checks ownership at runtime
    hal1request = call SingleChannel.getSingleData[client](&settings);
    return hal1request;
  }

  event void Resource.granted[uint8_t client]() 
  {
    // signalled only for Read
    msp430adc12_channel_config_t settings;
    error_t hal1request;
    
    settings = call Config.getChannelSettings[client]();
    if (settings.inch == INPUT_CHANNEL_NONE){
      call Resource.release[client]();
      signal Read.readDone[client](EINVAL, 0);
      return;
    }
    readSync = TRUE;
    hal1request = call SingleChannel.getSingleData[client](&settings);
    if (hal1request != SUCCESS){
      readSync = FALSE;
      call Resource.release[client]();
      signal Read.readDone[client](FAIL, 0);
    }
  }
  
  void task readDone()
  {
    call Resource.release[owner]();
    signal Read.readDone[owner](SUCCESS, value);
  }

  async event error_t SingleChannel.singleDataReady[uint8_t client](uint16_t data)
  {
    if (readSync){ // was Read.read request
      readSync = FALSE;
      owner = client;
      value = data;
      post readDone();
    } else { // was ReadNow.read request
      signal ReadNow.readDone[client](SUCCESS, data);
    }
    return SUCCESS;
  }

  async event uint16_t* SingleChannel.multipleDataReady[uint8_t client](
      uint16_t *buf, uint16_t length)
  {
    // won't happen
    return 0;
  }
  
  
  command error_t ReadStream.postBuffer[uint8_t rsClient]( uint16_t* buf, uint16_t count )
  {
    struct list_entry_t *newEntry = (struct list_entry_t *) buf;
    
    newEntry->count = count;
    newEntry->next = 0;
    atomic {
      if (!streamBuf[rsClient])
        streamBuf[rsClient] = newEntry;
      else {
        struct list_entry_t *tmp = streamBuf[rsClient];
        while (tmp->next)
          tmp = tmp->next;
        tmp->next = newEntry;
      }
    }
    return SUCCESS;
  }
  
  command error_t ReadStream.read[uint8_t rsClient]( uint32_t _usPeriod )
  {
    error_t requested = call ResourceReadStream.request[rsClient]();
    if (requested != SUCCESS || !streamBuf[rsClient])
      return FAIL;
    usPeriod[rsClient] = _usPeriod;
    return SUCCESS;
  }
  
  event void ResourceReadStream.granted[uint8_t rsClient]() 
  {
    error_t hal1request;
    struct list_entry_t *entry = streamBuf[rsClient];
    msp430adc12_channel_config_t settings = 
      call ConfigReadStream.getChannelSettings[rsClient]();
    
    if (!entry || settings.inch == INPUT_CHANNEL_NONE){
      // no buffers available
      call ResourceReadStream.release[rsClient]();
      signal ReadStream.readDone[rsClient]( FAIL, 0 );
      return;
    }
    owner = rsClient;
    streamSettings = settings;
    streamSettings.sampcon_ssel = SAMPCON_SOURCE_SMCLK; // assumption: SMCLK runs at 1 MHz
    streamSettings.sampcon_id = SAMPCON_CLOCK_DIV_1; 
    streamBuf[rsClient] = entry->next;
    hal1request = call SingleChannelReadStream.getMultipleData[rsClient](
      &streamSettings, (uint16_t *) entry, entry->count, usPeriod[rsClient]);
    if (hal1request != SUCCESS){
      streamBuf[rsClient] = entry;
      post finishStreamRequest();
      return;
    }
  }

  void task finishStreamRequest()
  {
    call ResourceReadStream.release[owner]();
    if (!streamBuf[owner])
      // all posted buffers were filled
      signal ReadStream.readDone[owner]( SUCCESS, usPeriod[owner] );
    else {
      // not all buffers were filled
      do {
        signal ReadStream.bufferDone[owner]( FAIL, (uint16_t *) streamBuf[owner], 0);
        streamBuf[owner] = streamBuf[owner]->next;
      } while (streamBuf[owner]);
      signal ReadStream.readDone[owner]( FAIL, 0 );
    }
  }

  async event uint16_t* SingleChannelReadStream.multipleDataReady[uint8_t rsClient](
      uint16_t *buf, uint16_t length)
  {
    error_t nextRequest;
    
    if (!resultBuf){
      value = length;
      resultBuf = buf;
      post signalBufferDone();
      if (!streamBuf[rsClient])
        post finishStreamRequest();
      else {
        // fill next buffer (this is the only async code dealing with buffers)
        struct list_entry_t *entry = streamBuf[rsClient];
        streamBuf[rsClient] = streamBuf[rsClient]->next;
        nextRequest = call SingleChannelReadStream.getMultipleData[rsClient](
          &streamSettings, (uint16_t *) entry, entry->count, usPeriod[rsClient]);
        if (nextRequest != SUCCESS){
          streamBuf[owner] = entry;
          post finishStreamRequest();
        }
      }
    } else {
      // overflow: can't signal data fast enough
      struct list_entry_t *entry = (struct list_entry_t *) buf;
      entry->next = streamBuf[rsClient];
      streamBuf[rsClient] = entry; // what a waste
      post finishStreamRequest();
    }
    return 0;
  }

  void task signalBufferDone()
  {
    signal ReadStream.bufferDone[owner]( SUCCESS, resultBuf, value);
    resultBuf = 0;
  }
  
  async event error_t SingleChannelReadStream.singleDataReady[uint8_t rsClient](uint16_t data)
  {
    // won't happen
    return SUCCESS;
  }

  default async command error_t Resource.request[uint8_t client]() { return FAIL; }
  default async command error_t Resource.immediateRequest[uint8_t client]() { return FAIL; }
  default async command void Resource.release[uint8_t client]() { }
  default event void Read.readDone[uint8_t client]( error_t result, uint16_t val ){}
  default async event void ReadNow.readDone[uint8_t client]( error_t result, uint16_t val ){}
  
  default async command error_t ResourceReadStream.request[uint8_t rsClient]() { return FAIL; }
  default async command void ResourceReadStream.release[uint8_t rsClient]() { }
  default event void ReadStream.bufferDone[uint8_t rsClient]( error_t result, 
			 uint16_t* buf, uint16_t count ){}
  default event void ReadStream.readDone[uint8_t rsClient]( error_t result, uint32_t actualPeriod ){ } 

  default async command error_t 
    SingleChannel.getSingleData[uint8_t client](const msp430adc12_channel_config_t *config)
  {
    return EINVAL;
  }

  default async command msp430adc12_channel_config_t 
    Config.getChannelSettings[uint8_t client]()
  { 
    msp430adc12_channel_config_t defaultConfig = {INPUT_CHANNEL_NONE,0,0,0,0,0,0,0}; 
    return defaultConfig;
  }

  default async command error_t 
    SingleChannelReadStream.getMultipleData[uint8_t client](
      const msp430adc12_channel_config_t *config,
      uint16_t *buf, uint16_t length, uint16_t jiffies)
  {
    return EINVAL;
  }

  default async command msp430adc12_channel_config_t 
    ConfigReadStream.getChannelSettings[uint8_t client]()
  { 
    msp430adc12_channel_config_t defaultConfig = {INPUT_CHANNEL_NONE,0,0,0,0,0,0,0}; 
    return defaultConfig;
  }
}

