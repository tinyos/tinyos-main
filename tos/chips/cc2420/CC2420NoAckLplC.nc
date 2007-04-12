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
 * This is experimental because:
 *  > Acknowledgements really don't work at all, even on the last message
 *    which is supposed to return an acknowledgement from the receiver.
 *  > The CRC is not yet manually calculated, so the entire continuous
 *    modulation doesn't contain any useful information.
 *    By adding in the CRC calcuation functionality to TransmitP,
 *    we can better support mobile nodes that walk out of range and
 *    lossy connections.  We could also put receivers back to sleep that
 *    the "preamble" is not destined for, because the actual preamble
 *    would have an address associated with it.
 *
 * @author David Moss
 */
 
#include "CC2420NoAckLpl.h"
#warning "*** USING EXPERIMENTAL NO-ACK LOW POWER LISTENING LAYER"

configuration CC2420NoAckLplC {
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
      CC2420NoAckLplP,
      CC2420DutyCycleC,
      CC2420ActiveMessageC,
      CC2420CsmaC,
      CC2420TransmitC,
      CC2420PacketC,
      RandomC,
      LedsC,
      new StateC() as SendStateC,
      new StateC() as RadioStateC,
      new TimerMilliC() as OffTimerC;
  
  LowPowerListening = CC2420NoAckLplP;
  Send = CC2420NoAckLplP;
  Receive = CC2420NoAckLplP;
  SplitControl = CC2420DutyCycleC;
  SendState = SendStateC;
  
  SubControl = CC2420NoAckLplP.SubControl;
  SubReceive = CC2420NoAckLplP.SubReceive;
  SubSend = CC2420NoAckLplP.SubSend;
  
  
  MainC.SoftwareInit -> CC2420NoAckLplP;
  
  CC2420NoAckLplP.Random -> RandomC;
  CC2420NoAckLplP.SendState -> SendStateC;
  CC2420NoAckLplP.RadioState -> RadioStateC;
  CC2420NoAckLplP.SplitControlState -> CC2420DutyCycleC;
  CC2420NoAckLplP.CC2420Cca -> CC2420TransmitC;
  CC2420NoAckLplP.OffTimer -> OffTimerC;
  CC2420NoAckLplP.CC2420DutyCycle -> CC2420DutyCycleC;
  CC2420NoAckLplP.Resend -> CC2420TransmitC;
  CC2420NoAckLplP.PacketAcknowledgements -> CC2420ActiveMessageC;
  CC2420NoAckLplP.AMPacket -> CC2420ActiveMessageC;
  CC2420NoAckLplP.CC2420Packet -> CC2420PacketC;
  CC2420NoAckLplP.RadioBackoff -> CC2420CsmaC;
  CC2420NoAckLplP.Leds -> LedsC;
  
}

