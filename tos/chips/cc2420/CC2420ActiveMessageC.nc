/*									tab:4
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * The Active Message layer for the CC2420 radio. This configuration
 * just layers the AM dispatch (CC2420ActiveMessageM) on top of the
 * underlying CC2420 radio packet (CC2420CsmaCsmaCC), which is
 * inherently an AM packet (acknowledgements based on AM destination
 * addr and group). Note that snooping may not work, due to CC2420
 * early packet rejection if acknowledgements are enabled.
 *
 * @author Philip Levis
 * @author David Moss
 * @version $Revision: 1.8 $ $Date: 2007-07-04 00:37:14 $
 */

#include "CC2420.h"
#include "AM.h"

configuration CC2420ActiveMessageC {
  provides {
    interface SplitControl;
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface AMPacket;
    interface Packet;
    interface CC2420Packet;
    interface PacketAcknowledgements;
    interface RadioBackoff[am_id_t amId];
    interface LowPowerListening;
    interface PacketLink;
  }
}
implementation {

  components CC2420ActiveMessageP as AM;
  components CC2420CsmaC as CsmaC;
  components ActiveMessageAddressC;
  components UniqueSendC;
  components UniqueReceiveC;
  components CC2420TinyosNetworkC;
  components CC2420PacketC;
  components CC2420ControlC;
  
#if defined(LOW_POWER_LISTENING) || defined(ACK_LOW_POWER_LISTENING)
  components DefaultLplC as LplC;
#else
  components DummyLplC as LplC;
#endif

#if defined(PACKET_LINK)
  components PacketLinkC as LinkC;
#else
  components PacketLinkDummyC as LinkC;
#endif

  
  RadioBackoff = CsmaC;
  Packet = AM;
  AMSend = AM;
  Receive = AM.Receive;
  Snoop = AM.Snoop;
  AMPacket = AM;
  PacketLink = LinkC;
  LowPowerListening = LplC;
  CC2420Packet = CC2420PacketC;
  PacketAcknowledgements = CC2420PacketC;
  
  
  // SplitControl Layers
  SplitControl = LplC;
  LplC.SubControl -> CsmaC;
  
  // Send Layers
  AM.SubSend -> UniqueSendC;
  UniqueSendC.SubSend -> LinkC;
  LinkC.SubSend -> LplC.Send;
  LplC.SubSend -> CC2420TinyosNetworkC.Send;
  CC2420TinyosNetworkC.SubSend -> CsmaC;
  
  // Receive Layers
  AM.SubReceive -> LplC;
  LplC.SubReceive -> UniqueReceiveC.Receive;
  UniqueReceiveC.SubReceive -> CC2420TinyosNetworkC.Receive;
  CC2420TinyosNetworkC.SubReceive -> CsmaC;

  AM.ActiveMessageAddress -> ActiveMessageAddressC;
  AM.CC2420Packet -> CC2420PacketC;
  AM.CC2420PacketBody -> CC2420PacketC;
  AM.CC2420Config -> CC2420ControlC;
  
}
