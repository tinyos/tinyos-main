/*
 * Copyright (c) 2006, Technische Universität Berlin
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
 * - Neither the name of the Technische Universität Berlin nor the names 
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
 * $Revision: 1.5 $
 * $Date: 2007-04-05 13:42:36 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

module Msp430RefVoltArbiterImplP
{
  provides interface Resource as ClientResource[uint8_t client];
  uses {
    interface Resource as AdcResource[uint8_t client];
    interface SplitControl as RefVolt_1_5V;
    interface SplitControl as RefVolt_2_5V;  
    interface AdcConfigure<const msp430adc12_channel_config_t*> as Config[uint8_t client];
  }
} implementation {
  enum {
    NO_OWNER = 0xFF,
  };
  norace uint8_t syncOwner = NO_OWNER;
  bool ref2_5v;

  task void switchOff();
  
  async command error_t ClientResource.request[uint8_t client]()
  {
    return call AdcResource.request[client]();
  }
   
  async command error_t ClientResource.immediateRequest[uint8_t client]()
  {
    const msp430adc12_channel_config_t* settings = call Config.getConfiguration[client]();
    if (settings->sref == REFERENCE_VREFplus_AVss ||
        settings->sref == REFERENCE_VREFplus_VREFnegterm)
      // always fails, because of the possible start-up delay (and async-sync transition)
      return FAIL;
    else {
      return call AdcResource.immediateRequest[client]();
    }
  }

  event void AdcResource.granted[uint8_t client]()
  {
    const msp430adc12_channel_config_t* settings  = call Config.getConfiguration[client]();
    if (settings->sref == REFERENCE_VREFplus_AVss ||
        settings->sref == REFERENCE_VREFplus_VREFnegterm){
      error_t started;
      if (syncOwner != NO_OWNER){
        // very rare case, which can only occur 
        // if no FIFO task scheduler
        // is used (see comment below)
        call AdcResource.release[client]();
        call AdcResource.request[client]();
        return;
      }
      syncOwner = client;
      if (settings->ref2_5v == REFVOLT_LEVEL_1_5) {
        ref2_5v = FALSE;
        started = call RefVolt_1_5V.start();
      }
      else {
        ref2_5v = TRUE;
        started = call RefVolt_2_5V.start();
      }
      if (started != SUCCESS){
        syncOwner = NO_OWNER;
        call AdcResource.release[client]();
        call AdcResource.request[client]();
      }
    } else 
      signal ClientResource.granted[client]();
  }
   
  event void RefVolt_1_5V.startDone(error_t error)
  {
    if (syncOwner != NO_OWNER){
      // assumption: a client which has called request() must
      // not call release() before it gets the granted()
      signal ClientResource.granted[syncOwner]();
    }
  }
   
  event void RefVolt_2_5V.startDone(error_t error)
  {
    if (syncOwner != NO_OWNER){
      // assumption: a client which has called request() must
      // not call release() before it gets the granted()
      signal ClientResource.granted[syncOwner]();
    }
  }

  async command error_t ClientResource.release[uint8_t client]()
  {
    error_t error;
    if (syncOwner == client)
      post switchOff();  
    error = call AdcResource.release[client]();
    // If syncOwner == client then now there is an inconsistency between 
    // the state of syncOwner and the actual owner of the Resource 
    // (which is not owned by anyone, because it was just released). 
    // The switchOff() task will resolve this incosistency, but a 
    // client can call ClientResource.request() before this task is 
    // posted. However, since Resource.granted is signalled in task context,
    // with a FIFO task scheduler we can be sure that switchOff() will
    // always be executed before the next Resource.granted event is 
    // signalled. Unfortunately "TinyOS components MUST NOT assume a 
    // FIFO policy" (TEP106), that's why there is some additional check
    // in AdcResource.granted above.
    return error;
  }

  task void switchOff()
  {
    error_t stopped;
    // update internal state
    if (syncOwner != NO_OWNER){
      if (ref2_5v)
        stopped = call RefVolt_2_5V.stop();
      else
        stopped = call RefVolt_1_5V.stop();
      if (stopped == SUCCESS)
        syncOwner = NO_OWNER;
      else
        post switchOff();
    }
  }

  event void RefVolt_1_5V.stopDone(error_t error)
  {
  }
  
  event void RefVolt_2_5V.stopDone(error_t error)
  {
  }

  async command bool ClientResource.isOwner[uint8_t client]()
  {
    return call AdcResource.isOwner[client]();
  }

  default event void ClientResource.granted[uint8_t client](){}
  default async command error_t AdcResource.request[uint8_t client]()
  {
    return FAIL;
  }
  default async command error_t AdcResource.immediateRequest[uint8_t client]()
  {
    return FAIL;
  }
  default async command bool AdcResource.isOwner[uint8_t client]() { return FALSE; }
  default async command error_t AdcResource.release[uint8_t client](){return FAIL;}
  const msp430adc12_channel_config_t defaultConfig = {INPUT_CHANNEL_NONE,0,0,0,0,0,0,0}; 
  default async command const msp430adc12_channel_config_t*
    Config.getConfiguration[uint8_t client]()
  { 
    return &defaultConfig;
  }
}  

