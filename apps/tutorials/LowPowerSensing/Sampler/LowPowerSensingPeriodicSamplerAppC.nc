/*
 * Copyright (c) 2007 Stanford University.
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
 * @date July 24, 2007
 */

#include "LowPowerSensingConstants.h"
#include "SensorSample.h"
configuration LowPowerSensingPeriodicSamplerAppC {}
implementation {
  components new SamplePeriodicLogC(SAMPLING_INTERVAL, VOLUME_SENSOR_SAMPLES);
  components MainC, LowPowerSensingPeriodicSamplerC as App;
  components SampleNxConverterC;
  MainC.Boot <- App;
  App.SampleLogRead -> SamplePeriodicLogC;
  App.SampleNxConverter -> SampleNxConverterC;

  components ActiveMessageC;
  App.AMControl -> ActiveMessageC;
  App.AMPacket -> ActiveMessageC;
  App.Packet -> ActiveMessageC;

  components new AMSenderC(AM_SAMPLE_MSG) as SampleSender;
  App.SampleSend -> SampleSender;

  components new AMReceiverC(AM_REQUEST_SAMPLES_MSG) as RequestSamplesReceiver;
  App.RequestSamplesReceive -> RequestSamplesReceiver;

  components LedsC as LedsC;
  App.Leds -> LedsC;

//Nasty hack since no uniform way of prividing LPL support as of yet
#if defined(PLATFORM_TELOSB) || defined(PLATFORM_TMOTE) || defined(PLATFORM_MICAZ)
  components CC2420ActiveMessageC as LPLProvider;
  App.LPL -> LPLProvider;
#endif

#if defined(PLATFORM_MICA2)
  components CC1000CsmaRadioC as LPLProvider;
  App.LPL -> LPLProvider;
#endif

#if defined(PLATFORM_IRIS)
  components ActiveMessageC as LPLProvider;
  App.LPL -> LPLProvider;
#endif

}

