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
 * @version $Revision: 1.16 $ $Date: 2010-06-29 22:07:44 $
 */

#include "CC2420.h"
#include "AM.h"
#include "Ieee154.h"
#include "IeeeEui64.h"
#ifdef IEEE154FRAMES_ENABLED
#error "CC2420 AM layer cannot work when IEEE 802.15.4 frames only are used"
#endif

configuration CC2420ActiveMessageC {
  provides {
    interface SplitControl;
    interface AMSend[uint8_t id];
    interface Receive[uint8_t id];
    interface Receive as Snoop[uint8_t id];
    interface AMPacket;
    interface Packet;
    interface CC2420Packet;
    interface PacketAcknowledgements;



    interface PacketLink;
    interface SendNotifier[uint8_t amId];
  }
}
implementation {
  enum {
    CC2420_AM_SEND_ID     = unique(RADIO_SEND_RESOURCE),
  };

  components CC2420RadioC as Radio;
  components TossimActiveMessageP as AM;
  components ActiveMessageAddressC;
  components CC2420CsmaC as CsmaC;

  components CC2420PacketC;
  components NetworkC as Network; 

  SplitControl = Radio;

  Packet = AM;
  AMSend = AM;
  SendNotifier = AM;
  Receive = AM.Receive;
  Snoop = AM.Snoop;
  AMPacket = AM;

  PacketLink = Radio;

  CC2420Packet = Radio;
  PacketAcknowledgements = Radio;

  
  // Radio resource for the AM layer
  AM.SubSend -> Radio.ActiveSend;
  AM.SubReceive -> Radio.ActiveReceive;

  AM.amAddress -> ActiveMessageAddressC;

}


