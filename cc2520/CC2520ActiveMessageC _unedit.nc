/*
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
 * The Active Message layer for the CC2520 radio. This configuration
 * just layers the AM dispatch (CC2520ActiveMessageM) on top of the
 * underlying CC2520 radio packet (CC2520CsmaCsmaCC), which is
 * inherently an AM packet (acknowledgements based on AM destination
 * addr and group). Note that snooping may not work, due to CC2520
 * early packet rejection if acknowledgements are enabled.
 *
 * @author Philip Levis
 * @author David Moss
 * @version $Revision: 1.12 $ $Date: 2008/06/11 00:46:23 $
 */

#include "CC2520.h"
#include "AM.h"

configuration CC2520ActiveMessageC {
  provides {
    interface SplitControl;
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface AMPacket;
    interface Packet;
    interface CC2520Packet;
    interface PacketAcknowledgements;
    interface LinkPacketMetadata;
    interface RadioBackoff[am_id_t amId];
    interface LowPowerListening;
    interface PacketLink;
    interface SendNotifier[am_id_t amId];
  }
}
implementation {

  components CC2520ActiveMessageP as AM;
  components CC2520CsmaC as CsmaC;
  components ActiveMessageAddressC;
  components UniqueSendC;
  components UniqueReceiveC;
  components CC2520TinyosNetworkC;
  components CC2520PacketC;
  components CC2520ControlC;
  
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

  
  RadioBackoff = AM;
  Packet = AM;
  AMSend = AM;
  SendNotifier = AM;
  Receive = AM.Receive;
  Snoop = AM.Snoop;
  AMPacket = AM;
  PacketLink = LinkC;
  LowPowerListening = LplC;
  CC2520Packet = CC2520PacketC;
  PacketAcknowledgements = CC2520PacketC;
  LinkPacketMetadata = CC2520PacketC;
  
  // SplitControl Layers
  SplitControl = LplC;
  LplC.SubControl -> CsmaC;
  
  // Send Layers
  AM.SubSend -> UniqueSendC;
  UniqueSendC.SubSend -> LinkC;
  LinkC.SubSend -> LplC.Send;
  LplC.SubSend -> CC2520TinyosNetworkC.Send;
  CC2520TinyosNetworkC.SubSend -> CsmaC;
  
  // Receive Layers
  AM.SubReceive -> LplC;
  LplC.SubReceive -> UniqueReceiveC.Receive;
  UniqueReceiveC.SubReceive -> CC2520TinyosNetworkC.Receive;
  CC2520TinyosNetworkC.SubReceive -> CsmaC;

  AM.ActiveMessageAddress -> ActiveMessageAddressC;
  AM.CC2520Packet -> CC2520PacketC;
  AM.CC2520PacketBody -> CC2520PacketC;
  AM.CC2520Config -> CC2520ControlC;
  
  AM.SubBackoff -> CsmaC;
  
}
