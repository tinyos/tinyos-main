/* Copyright (c) 2007 Shockfish SA
*  All rights reserved.
*
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author Maxime Muller
 *
 */

#include "message.h"
#include "XE1205.h"

configuration XE1205CsmaRadioC {
    provides {
	interface SplitControl;
	interface Send;
	interface Receive;
	interface Packet;
	interface CsmaControl;
	interface CsmaBackoff[am_id_t amId];
	interface PacketAcknowledgements;
	interface LPLControl;
    }
}
implementation {
    components XE1205CsmaP as CsmaP;
    components XE1205SendReceiveP as SendReceive;
    components XE1205PhyP;
    components new TimerMilliC() as BackoffTimerC;
    components MainC, RandomC,ActiveMessageC, ActiveMessageAddressC;
    
    MainC.SoftwareInit -> CsmaP;
    
    Send =  CsmaP;
    Receive = CsmaP;
    Packet =  SendReceive;
    PacketAcknowledgements = SendReceive;
    
    SplitControl = CsmaP;
    CsmaControl = CsmaP;
    CsmaBackoff = CsmaP;
    LPLControl = CsmaP;
  

    CsmaP.SubControl -> SendReceive.SplitControl;
    CsmaP.SubReceive -> SendReceive.Receive;
    CsmaP.SubSend ->  SendReceive.Send;
    CsmaP.Rssi -> XE1205PhyP.XE1205PhyRssi;
    CsmaP.BackoffTimer -> BackoffTimerC;
    CsmaP.Random -> RandomC;

}
