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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
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


#include "CC2420AckLpl.h"
#warning "*** USING ACK LOW POWER LISTENING LAYER"

configuration CC2420AckLplC {
  provides {
    interface LowPowerListening;
    interface Send;
    interface Receive;
    interface SplitControl;
    interface State as SendState;
  }
  
  uses { 
    interface Send as SubSend;
    interface Receive as SubReceive;
    interface SplitControl as SubControl;
  }
}

implementation {
  components MainC,
      CC2420AckLplP,
      CC2420DutyCycleC,
      CC2420ActiveMessageC,
      CC2420CsmaC,
      CC2420TransmitC,
      CC2420PacketC,
      RandomC,
      LedsC,
      new StateC() as SendStateC,
      new StateC() as RadioStateC,
      new TimerMilliC() as OffTimerC,
      new TimerMilliC() as SendDoneTimerC;
  
  LowPowerListening = CC2420AckLplP;
  Send = CC2420AckLplP;
  Receive = CC2420AckLplP;
  SplitControl = CC2420DutyCycleC;
  SendState = SendStateC;
  
  SubControl = CC2420AckLplP.SubControl;
  SubReceive = CC2420AckLplP.SubReceive;
  SubSend = CC2420AckLplP.SubSend;
  
  
  MainC.SoftwareInit -> CC2420AckLplP;
  
  CC2420AckLplP.Random -> RandomC;
  CC2420AckLplP.SendState -> SendStateC;
  CC2420AckLplP.RadioState -> RadioStateC;
  CC2420AckLplP.SplitControlState -> CC2420DutyCycleC;
  CC2420AckLplP.OffTimer -> OffTimerC;
  CC2420AckLplP.SendDoneTimer -> SendDoneTimerC;
  CC2420AckLplP.CC2420DutyCycle -> CC2420DutyCycleC;
  CC2420AckLplP.Resend -> CC2420TransmitC;
  CC2420AckLplP.PacketAcknowledgements -> CC2420ActiveMessageC;
  CC2420AckLplP.AMPacket -> CC2420ActiveMessageC;
  CC2420AckLplP.CC2420Packet -> CC2420PacketC;
  CC2420AckLplP.Leds -> LedsC;
  
}
