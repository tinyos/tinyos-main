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
 * The Active Message layer for the CC2420 radio. This configuration
 * just layers the AM dispatch (CC2420ActiveMessageM) on top of the
 * underlying CC2420 radio packet (CC2420CsmaCsmaCC), which is
 * inherently an AM packet (acknowledgements based on AM destination
 * addr and group). Note that snooping may not work, due to CC2420
 * early packet rejection if acknowledgements are enabled.
 *
 * @author Philip Levis
 * @author David Moss
 * @version $Revision: 1.2 $ $Date: 2009-10-28 05:29:02 $
 */

#include "CC2420.h"
#include "AM.h"
#include "Ieee154.h"

#ifdef IEEE154FRAMES_ENABLED
#error "CC2420 AM layer cannot work when IEEE 802.15.4 frames only are used"
#endif

configuration CC2420ActiveMessageC {
  provides {
    interface SplitControl;
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as ReceiveDefault[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface Receive as SnoopDefault[am_id_t id];
    interface AMPacket;
    interface Packet;
    interface CC2420Packet;
    interface PacketAcknowledgements;
    interface LinkPacketMetadata;
    interface RadioBackoff[am_id_t amId];
    interface LowPowerListening;
    interface PacketLink;
    interface SendNotifier[am_id_t amId];
  }
}
implementation {
  enum {
    CC2420_AM_SEND_ID     = unique(IEEE154_SEND_CLIENT),
  };

  components CC2420RadioC as Radio;
  components CC2420ActiveMessageP as AM;
  components ActiveMessageAddressC;
  components CC2420CsmaC as CsmaC;
  components CC2420ControlC;
  components CC2420PacketC;
  
  SplitControl = Radio;
  RadioBackoff = AM;
  Packet = AM;
  AMSend = AM;
  SendNotifier = AM;
  Receive = AM.Receive;
  ReceiveDefault = AM.ReceiveDefault;
  Snoop = AM.Snoop;
  SnoopDefault = AM.SnoopDefault;
  AMPacket = AM;
  PacketLink = Radio;
  LowPowerListening = Radio;
  CC2420Packet = Radio;
  PacketAcknowledgements = Radio;
  LinkPacketMetadata = Radio;
  
  // Radio resource for the AM layer
  AM.RadioResource -> Radio.Resource[CC2420_AM_SEND_ID];
  AM.SubSend -> Radio.ActiveSend;
  AM.SubReceive -> Radio.ActiveReceive;

  AM.ActiveMessageAddress -> ActiveMessageAddressC;
  AM.CC2420Packet -> CC2420PacketC;
  AM.CC2420PacketBody -> CC2420PacketC;
  AM.CC2420Config -> CC2420ControlC;
  
  AM.SubBackoff -> CsmaC;

  components LedsC;
  AM.Leds -> LedsC;
}


