/* Copyright (c) 2007 Shockfish SA
*  All rights reserved.
*
*  Permission to use, copy, modify, and distribute this software and its
*  documentation for any purpose, without fee, and without written
*  agreement is hereby granted, provided that the above copyright
*  notice, the (updated) modification history and the author appear in
*  all copies of this source code.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
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
