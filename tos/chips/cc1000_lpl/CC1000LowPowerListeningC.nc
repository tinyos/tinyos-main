/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
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
 */

/**
 * Low Power Listening for the CC1000
 * @author David Moss
 */
 
#include "CC1000LowPowerListening.h"

configuration CC1000LowPowerListeningC {
  provides {
    interface Send;
    interface Receive;
    interface CsmaBackoff[am_id_t amId];
  }
}

implementation {
  components MainC,
      CC1000ActiveMessageC,
      CC1000LowPowerListeningP,
      CC1000CsmaRadioC,
      RandomC,
      new StateC() as SendStateC,
      new StateC() as RadioPowerStateC,
      new TimerMilliC() as SendDoneTimerC;
  
  Send = CC1000LowPowerListeningP;
  Receive = CC1000LowPowerListeningP;
  CsmaBackoff = CC1000LowPowerListeningP;
  
  MainC.SoftwareInit -> CC1000LowPowerListeningP;
   
  CC1000LowPowerListeningP.AMPacket -> CC1000ActiveMessageC;
  CC1000LowPowerListeningP.Random -> RandomC;
  CC1000LowPowerListeningP.SendState -> SendStateC;
  CC1000LowPowerListeningP.RadioPowerState -> RadioPowerStateC;
  CC1000LowPowerListeningP.SendDoneTimer -> SendDoneTimerC;
  CC1000LowPowerListeningP.SubSend -> CC1000CsmaRadioC;
  CC1000LowPowerListeningP.SubReceive -> CC1000CsmaRadioC;
  CC1000LowPowerListeningP.SubControl -> CC1000CsmaRadioC;
  CC1000LowPowerListeningP.PacketAcknowledgements -> CC1000CsmaRadioC;
  CC1000LowPowerListeningP.SubBackoff -> CC1000CsmaRadioC;
  CC1000LowPowerListeningP.CsmaControl -> CC1000CsmaRadioC;
  CC1000LowPowerListeningP.LowPowerListening -> CC1000CsmaRadioC;
  
}

