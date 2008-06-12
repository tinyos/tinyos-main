/*
 * Copyright (c) 2008 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */
 
#include "thread.h"

configuration BlockingAdcP {
  provides {
    interface BlockingRead<uint16_t> as BlockingRead[uint8_t client];
    interface BlockingReadStream<uint16_t> as BlockingReadStream[uint8_t streamClient];
  }
  uses {
    //For BlockingRead
    interface AdcConfigure<const msp430adc12_channel_config_t*> as Config[uint8_t client];
    interface Msp430Adc12SingleChannel as SingleChannel[uint8_t client];
    interface Resource as ResourceRead[uint8_t client];
    
    //For BlockingReadStream
    interface AdcConfigure<const msp430adc12_channel_config_t*> as ConfigReadStream[uint8_t streamClient];
    interface Msp430Adc12SingleChannel as SingleChannelReadStream[uint8_t streamClient];
    interface Resource as ResourceReadStream[uint8_t streamClient];
  }
}
implementation {
  components MainC;
  components AdcP;
  components WireAdcStreamP;
  components BlockingAdcImplP;
  
  MainC.SoftwareInit -> BlockingAdcImplP;
  
  //For BlockingRead
  BlockingRead = BlockingAdcImplP;
  Config = AdcP.Config;
  SingleChannel = AdcP.SingleChannel;
  ResourceRead = AdcP.ResourceRead;
  BlockingAdcImplP.Read -> AdcP.Read;
  
  //For BlockingReadStream
  BlockingReadStream = BlockingAdcImplP;
  ConfigReadStream = WireAdcStreamP;
  SingleChannelReadStream = WireAdcStreamP;
  ResourceReadStream = WireAdcStreamP;
  BlockingAdcImplP.ReadStream -> WireAdcStreamP;
  
  components SystemCallC;
  components SystemCallQueueC;
  BlockingAdcImplP.SystemCallQueue -> SystemCallQueueC;
  BlockingAdcImplP.SystemCall -> SystemCallC;
}


