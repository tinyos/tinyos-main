#include <DisseminationEngine.h>

/*
 * Copyright (c) 2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

/**
 * The DisseminationEngineP component retrieves values from the
 * DisseminatorP components and disseminates them over the radio.
 *
 * TODO: Hook DisseminationProbe up to the serial instead of the radio.
 *
 * See TEP118 - Dissemination for details.
 * 
 * @author Gilman Tolle <gtolle@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:28 $
 */

configuration DisseminationEngineP {
  uses {
    interface DisseminationCache[uint16_t key];
    interface TrickleTimer[uint16_t key];
  }
}
implementation {
  components DisseminationEngineImplP;
  DisseminationCache = DisseminationEngineImplP;
  TrickleTimer = DisseminationEngineImplP;

  components MainC;  
  DisseminationEngineImplP.Boot -> MainC;

  components ActiveMessageC;
  DisseminationEngineImplP.RadioControl -> ActiveMessageC;

  components new AMSenderC(AM_DISSEMINATION_MESSAGE) as DisseminationSendC;
  DisseminationEngineImplP.AMSend -> DisseminationSendC.AMSend;

  components new AMReceiverC(AM_DISSEMINATION_MESSAGE) as DisseminationReceiveC;
  DisseminationEngineImplP.Receive -> DisseminationReceiveC.Receive;

  components new AMSenderC(AM_DISSEMINATION_PROBE_MESSAGE) as DisseminationProbeSendC;
  DisseminationEngineImplP.ProbeAMSend -> DisseminationProbeSendC.AMSend;

  components new AMReceiverC(AM_DISSEMINATION_PROBE_MESSAGE) 
    as DisseminationProbeReceiveC;
  DisseminationEngineImplP.ProbeReceive -> DisseminationProbeReceiveC.Receive;

  components NoLedsC;
  DisseminationEngineImplP.Leds -> NoLedsC;
}
