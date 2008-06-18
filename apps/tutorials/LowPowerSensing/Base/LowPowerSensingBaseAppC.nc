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
configuration LowPowerSensingBaseAppC{}
implementation {
  components MainC, LowPowerSensingBaseC as App;
  components new QueueC(message_t, MSG_QUEUE_SIZE) as Queue;
  components LedsC;
  MainC.Boot <- App;
  App.MsgQueue -> Queue;
  App.Leds -> LedsC;

  components SerialActiveMessageC as Serial;
  App.SerialAMControl -> Serial;
  App.SerialAMPacket -> Serial;
  App.SerialPacket -> Serial;

  components ActiveMessageC as Radio;
  App.RadioAMControl -> Radio;
  App.RadioAMPacket -> Radio;
  App.RadioPacket -> Radio;

  components new SerialAMReceiverC(AM_SERIAL_REQUEST_SAMPLES_MSG) as SerialRequestSampleMsgsReceiver;
  components new AMSenderC(AM_REQUEST_SAMPLES_MSG) as RadioRequestSampleMsgsSender;
  App.SerialRequestSampleMsgsReceive -> SerialRequestSampleMsgsReceiver;
  App.RadioRequestSampleMsgsSend -> RadioRequestSampleMsgsSender;

  components new AMReceiverC(AM_SAMPLE_MSG) as RadioSampleMsgReceiver;
  components new SerialAMSenderC(AM_SERIAL_SAMPLE_MSG) as SerialSampleMsgSender;
  App.RadioSampleMsgReceive -> RadioSampleMsgReceiver;
  App.SerialSampleMsgSend -> SerialSampleMsgSender;

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
  components RF230ActiveMessageC as LPLProvider;
  App.LPL -> LPLProvider;
#endif
}

