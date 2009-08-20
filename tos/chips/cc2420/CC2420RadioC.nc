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
 * Radio wiring for the CC2420.  This layer seperates the common
 * wiring of the lower-layer components of the CC2420 stack and makes
 * them available to clients like the AM stack and the IEEE802.15.4
 * stack.
 *
 * This component provides the highest-level internal interface to
 * other components of the CC2420 stack.
 *
 * @author Philip Levis
 * @author David Moss
 * @author Stephen Dawson-Haggerty
 * @version $Revision: 1.2 $ $Date: 2009-08-20 01:37:44 $
 */

#include "CC2420.h"

configuration CC2420RadioC {
  provides {
    interface SplitControl;

    interface Resource[uint8_t clientId];
    interface Send;
    interface Receive;

    interface Send as ActiveSend;
    interface Receive as ActiveReceive;

    interface CC2420Packet;
    interface PacketAcknowledgements;
    interface LinkPacketMetadata;
    interface LowPowerListening;
    interface PacketLink;

  }
}
implementation {

  components CC2420CsmaC as CsmaC;
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
  
  PacketLink = LinkC;
  LowPowerListening = LplC;
  CC2420Packet = CC2420PacketC;
  PacketAcknowledgements = CC2420PacketC;
  LinkPacketMetadata = CC2420PacketC;
  
  Resource = CC2420TinyosNetworkC;
  Send = CC2420TinyosNetworkC.Send;
  Receive = CC2420TinyosNetworkC.Receive;
  ActiveSend = CC2420TinyosNetworkC.ActiveSend;
  ActiveReceive = CC2420TinyosNetworkC.ActiveReceive;

  // SplitControl Layers
  SplitControl = LplC;
  LplC.SubControl -> CsmaC;
  
  // Send Layers
  CC2420TinyosNetworkC.SubSend -> UniqueSendC;
  UniqueSendC.SubSend -> LinkC;
  LinkC.SubSend -> LplC.Send;
  LplC.SubSend -> CsmaC;
  
  // Receive Layers
  CC2420TinyosNetworkC.SubReceive -> LplC;
  LplC.SubReceive -> UniqueReceiveC.Receive;
  UniqueReceiveC.SubReceive ->  CsmaC;
  
}
