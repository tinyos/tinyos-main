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
 * $Date: 2006-12-12 18:23:07 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include <Msp430Adc12.h>
#include <Msp430Dma.h>
module Msp430Adc12DMAP 
{
  provides {
    interface Msp430Adc12SingleChannel as SingleChannel[uint8_t id];
	}
	uses {
    interface Msp430DmaControl as DMAControl;
    interface Msp430DmaChannel as DMAChannel;
    interface Msp430Adc12SingleChannel as SubSingleChannel[uint8_t id];
    interface AsyncStdControl as AsyncAdcControl[uint8_t id];
	}
}
implementation
{ 
  enum {
    MULTIPLE_SINGLE,
    MULTIPLE_REPEAT,
    MULTIPLE_SINGLE_AGAIN,
  };

  // norace declarations are safe here, because Msp430Adc12P.nc implements 
  // a lock mechanism which guarantees that no two clients can access the ADC
  // and the module variables below are only changed after the lock was acquired
  norace uint8_t client;
  norace uint8_t mode;
  norace uint16_t *buffer;
  norace uint16_t numSamples;

  async command error_t SingleChannel.configureSingle[uint8_t id](
      const msp430adc12_channel_config_t *config)
  {
    // don't use DMA for single conversions
    return call SubSingleChannel.configureSingle[id](config);
  }

  async command error_t SingleChannel.configureSingleRepeat[uint8_t id](
      const msp430adc12_channel_config_t *config,
      uint16_t jiffies)
  {
    // don't use DMA for single conversions
    return call SubSingleChannel.configureSingleRepeat[id](config, jiffies);
  }
  
  error_t configure(uint8_t id, const msp430adc12_channel_config_t *config, 
      uint16_t *buf, uint16_t length, uint16_t jiffies, uint8_t _mode)
  {
    // for multiple samples single-channel repat-conversion mode
    // is used, because then there is only one interrupt at the
    // the end of the whole sequence and DMA has done all the copying
    error_t result = call SubSingleChannel.configureSingleRepeat[id](config, jiffies);
    if (result == SUCCESS){
      call DMAControl.init();
      call DMAControl.setFlags(ENABLE_NMI, NOT_ROUND_ROBIN, ON_FETCH);
      call DMAChannel.setupTransfer(
        DMA_REPEATED_SINGLE_TRANSFER, 
        DMA_TRIGGER_ADC12IFGx,
        DMA_EDGE_SENSITIVE,
        ADC12MEM,
        buf,
        length,
        DMA_WORD,
        DMA_WORD,
        DMA_ADDRESS_UNCHANGED,
        DMA_ADDRESS_INCREMENTED
        );
      call DMAChannel.startTransfer();
      client = id;
      mode = _mode;
      buffer = buf;
      numSamples = length;
      call AsyncAdcControl.start[id]();
    }
    return result;
  }

  async command error_t SingleChannel.configureMultiple[uint8_t id](
      const msp430adc12_channel_config_t *config,
      uint16_t *buf, uint16_t length, uint16_t jiffies)
  {
    return configure(id, config, buf, length, jiffies, MULTIPLE_SINGLE);
  }

  async command error_t SingleChannel.configureMultipleRepeat[uint8_t id](
      const msp430adc12_channel_config_t *config,
      uint16_t *buf, uint8_t length, uint16_t jiffies)
  {
    return configure(id, config, buf, length, jiffies, MULTIPLE_REPEAT);
  }

  async command error_t SingleChannel.getData[uint8_t id]()
  {
    if (mode == MULTIPLE_SINGLE_AGAIN)
      call DMAChannel.repeatTransfer(ADC12MEM, buffer, numSamples);
    return call SubSingleChannel.getData[id]();
  }
  
  async event error_t SubSingleChannel.singleDataReady[uint8_t id](uint16_t data)
  {
    // forward (only signalled if not in DMA mode)
    return signal SingleChannel.singleDataReady[id](data);
  }

  async event uint16_t* SubSingleChannel.multipleDataReady[uint8_t id](uint16_t buf[], uint16_t num)
  {
    // will never get here
    return 0;
  }
  
  async event void DMAChannel.transferDone(error_t success)
  {
    uint16_t* next;
    uint8_t oldMode = mode;
    if (oldMode != MULTIPLE_REPEAT){
      call AsyncAdcControl.stop[client]();
      mode = MULTIPLE_SINGLE_AGAIN;
    }
    next = signal SingleChannel.multipleDataReady[client](buffer, numSamples);
    if (oldMode == MULTIPLE_REPEAT)
      if (next){
        call DMAChannel.repeatTransfer(ADC12MEM, next, numSamples);
        call AsyncAdcControl.start[client]();
      } else
        call AsyncAdcControl.stop[client]();
  }

  default async command error_t SubSingleChannel.configureSingle[uint8_t id](
      const msp430adc12_channel_config_t *config)
  { return FAIL; }

  default async command error_t SubSingleChannel.configureSingleRepeat[uint8_t id](
      const msp430adc12_channel_config_t *config, uint16_t jiffies)
  { return FAIL; }
  
  default async command error_t SubSingleChannel.configureMultiple[uint8_t id]( 
      const msp430adc12_channel_config_t
      *config, uint16_t buf[], uint16_t num, uint16_t jiffies)
  { return FAIL; }

  default async command error_t SubSingleChannel.configureMultipleRepeat[uint8_t id](
      const msp430adc12_channel_config_t *config, uint16_t buf[], uint8_t
      num, uint16_t jiffies)
  { return FAIL; }

  default async command error_t SubSingleChannel.getData[uint8_t id]()
  { return FAIL;}

  default async event error_t SingleChannel.singleDataReady[uint8_t id](
      uint16_t data)
  { return FAIL; }

  default async event uint16_t* SingleChannel.multipleDataReady[uint8_t id](
      uint16_t buf[], uint16_t num)
  { return 0;}
  
  default async command error_t AsyncAdcControl.stop[uint8_t id]()
  { return FAIL; }
  default async command error_t AsyncAdcControl.start[uint8_t id]()
  { return FAIL; }
}
