/* 
 * Copyright (c) 2006, Ecole Polytechnique Federale de Lausanne (EPFL),
 * Switzerland.
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
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
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
 * ========================================================================
 */

/*
 * @author Henri Dubois-Ferriere
 *
 */
configuration XE1205ActiveMessageC {
  provides {
    interface SplitControl;
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as ReceiveDefault[am_id_t id];
    interface Receive as SnoopDefault[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface AMPacket;
    interface Packet;
    interface PacketAcknowledgements;
    #ifdef LOW_POWER_LISTENING
    interface LowPowerListening;
    #endif
  }
}
implementation {
  components XE1205SendReceiveC;
  Packet                 = XE1205SendReceiveC;
  PacketAcknowledgements = XE1205SendReceiveC;
 components XE1205ActiveMessageP;

#ifdef LOW_POWER_LISTENING
  components  XE1205LowPowerListeningC as Lpl;
  LowPowerListening = Lpl;
  XE1205ActiveMessageP.SubSend -> Lpl.Send;
  XE1205ActiveMessageP.SubReceive -> Lpl.Receive;
  SplitControl = Lpl;
#else
 
  XE1205ActiveMessageP.Packet     -> XE1205SendReceiveC;
  XE1205ActiveMessageP.SubSend    -> XE1205SendReceiveC.Send;
  XE1205ActiveMessageP.SubReceive -> XE1205SendReceiveC.Receive;
  SplitControl = XE1205SendReceiveC;
#endif
  AMPacket = XE1205ActiveMessageP;
  AMSend   = XE1205ActiveMessageP;
  Receive = XE1205ActiveMessageP.Receive;
  ReceiveDefault = XE1205ActiveMessageP.ReceiveDefault;
  Snoop = XE1205ActiveMessageP.Snoop;
  SnoopDefault = XE1205ActiveMessageP.SnoopDefault;


  components ActiveMessageAddressC;  
  XE1205ActiveMessageP.amAddress -> ActiveMessageAddressC;  


  components XE1205IrqConfC, XE1205PatternConfC, XE1205PhyRssiConfC;

}
