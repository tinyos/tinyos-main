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
 * Low Power Listening for the CC2420
 * @author David Moss
 */
 
#include "CC2420LowPowerListening.h"

configuration CC2420LowPowerListeningC {
  provides {
    interface LowPowerListening;
    interface Send;
    interface Receive;
    interface SplitControl;
  }
}

implementation {
  components MainC,
      CC2420LowPowerListeningP,
      CC2420DutyCycleC,
      CC2420ActiveMessageC,
      CC2420CsmaC,
      CC2420TransmitC,
      RandomC,
      new StateC() as SendStateC,
      new StateC() as RadioStateC,
      new TimerMilliC() as OffTimerC,
      new TimerMilliC() as SendDoneTimerC;
  
  LowPowerListening = CC2420LowPowerListeningP;
  Send = CC2420LowPowerListeningP;
  Receive = CC2420LowPowerListeningP;
  SplitControl = CC2420DutyCycleC;
  
  MainC.SoftwareInit -> CC2420LowPowerListeningP;
  
  CC2420LowPowerListeningP.Random -> RandomC;
  CC2420LowPowerListeningP.SendState -> SendStateC;
  CC2420LowPowerListeningP.RadioState -> RadioStateC;
  CC2420LowPowerListeningP.SplitControlState -> CC2420DutyCycleC;
  CC2420LowPowerListeningP.OffTimer -> OffTimerC;
  CC2420LowPowerListeningP.SendDoneTimer -> SendDoneTimerC;
  CC2420LowPowerListeningP.CC2420DutyCycle -> CC2420DutyCycleC;
  CC2420LowPowerListeningP.SubSend -> CC2420CsmaC;
  CC2420LowPowerListeningP.Resend -> CC2420TransmitC;
  CC2420LowPowerListeningP.SubReceive -> CC2420CsmaC;
  CC2420LowPowerListeningP.SubControl -> CC2420CsmaC;
  CC2420LowPowerListeningP.PacketAcknowledgements -> CC2420ActiveMessageC;
  CC2420LowPowerListeningP.AMPacket -> CC2420ActiveMessageC;
  
}

