#include "CC2420.h"

configuration CC2420RadioC {
  provides {
    interface SplitControl;
    interface Send as BareSend;
    interface Receive as BareReceive;
    interface Packet as BarePacket;
    interface Send    as ActiveSend;
    interface Receive as ActiveReceive;

    interface CC2420Packet;
    interface PacketAcknowledgements;


    interface PacketLink;

  }
}

implementation {
#if defined(PACKET_LINK)
  components PacketLinkC as LinkC;
#else
  components PacketLinkDummyC as LinkC;
#endif
  components CC2420CsmaC as CsmaC;
  components UniqueSendC;
  components UniqueReceiveC;
  components CC2420TinyosNetworkC;
  components CC2420PacketC;
  components DummyLplC as LplC;
  components NetworkC as Network;

  CC2420Packet = CC2420PacketC;
  PacketAcknowledgements = Network;
  PacketLink = LinkC;
  SplitControl = Network;
  SplitControl = CsmaC;

  BareSend = CC2420TinyosNetworkC.Send;
  BareReceive = CC2420TinyosNetworkC.Receive;
  BarePacket = CC2420TinyosNetworkC.BarePacket;

  ActiveSend = CC2420TinyosNetworkC.ActiveSend;
  ActiveReceive = CC2420TinyosNetworkC.ActiveReceive;
#if 1
  // Send Layers
  CC2420TinyosNetworkC.SubSend -> UniqueSendC;
  UniqueSendC.SubSend -> LinkC;
  LinkC.SubSend -> LplC.Send;
  LplC.SubSend -> CsmaC;

  // Receive Layers
  CC2420TinyosNetworkC.SubReceive -> LplC;
  LplC.SubReceive -> UniqueReceiveC.Receive;
  UniqueReceiveC.SubReceive ->  CsmaC;
#else
  // Send Layers
  CC2420TinyosNetworkC.SubSend -> LinkC;
  LinkC.SubSend -> LplC.Send;
  LplC.SubSend -> CsmaC;

  // Receive Layers
  CC2420TinyosNetworkC.SubReceive -> LplC;
  LplC.SubReceive -> CsmaC;
#endif
}

