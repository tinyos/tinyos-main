/**
 * IEEE 802.15.4 layer for the cc2420.  Provides a simplistic 
 *       link layer with dispatching on the 6lowpan "network" field
 *
 * @author Philip Levis
 * @author David Moss
 * @author Stephen Dawson-Haggerty
 * @version $Revision: 1.2 $ $Date: 2010-06-29 22:07:44 $
 */

#include "CC2420.h"
#ifdef TFRAMES_ENABLED
#error "The CC2420 Ieee 802.15.4 layer does not work with TFRAMES"
#endif

configuration CC2420Ieee154MessageC {
  provides {
    interface SplitControl;

    interface Resource as SendResource[uint8_t clientId];
    interface Ieee154Send;
    interface Receive as Ieee154Receive;

    interface Ieee154Packet;
    interface Packet;

    interface CC2420Packet;
    interface PacketAcknowledgements;
    interface LinkPacketMetadata;
    interface LowPowerListening;
    interface CC2420Config;
    interface PacketLink;
  }
}
implementation {

  components CC2420RadioC as Radio;
  components CC2420Ieee154MessageP as Msg;
  components CC2420PacketC;
  components CC2420ControlC;

  SendResource = Radio.Resource;
  Ieee154Receive = Msg;
  Ieee154Send = Msg;
  Ieee154Packet = Msg;
  Packet = Msg;
  CC2420Packet = CC2420PacketC;

  SplitControl = Radio;
  CC2420Packet = Radio;
  PacketAcknowledgements = Radio;
  LinkPacketMetadata = Radio;
  LowPowerListening = Radio;
  CC2420Config = CC2420ControlC;
  PacketLink = Radio;

  Msg.SubSend -> Radio.BareSend;
  Msg.SubReceive -> Radio.BareReceive;
#ifdef CC2420_IEEE154_RESOURCE_SEND
  Msg.Resource -> Radio.Resource[unique(RADIO_SEND_RESOURCE)];
#endif

  Msg.CC2420Packet -> CC2420PacketC;
  Msg.CC2420PacketBody -> CC2420PacketC;
  Msg.CC2420Config -> CC2420ControlC;

}
