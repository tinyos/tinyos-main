#include "CC2520.h"

configuration CC2520RadioC
{

 provides {
    interface SplitControl;
    interface Resource[uint8_t clientId];

    interface Send as BareSend;
    interface Receive as BareReceive;
    interface Packet as BarePacket;
    
    interface Send    as ActiveSend;
    interface Receive as ActiveReceive;

    interface CC2520Packet;
    interface PacketAcknowledgements;
    interface LinkPacketMetadata;
    interface LowPowerListening;
    interface PacketLink;
  }

}


implementation
{

  components CC2520CsmaC as CsmaC;
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
  //splitcontrol layers
  SplitControl=LplC;
  LplC.SubControl -> CsmaC;



  PacketLink = LinkC;
  LowPowerListening = LplC;
  CC2520Packet = CC2520PacketC;
  PacketAcknowledgements = CC2520PacketC;
  LinkPacketMetadata = CC2520PacketC;
  
  
   Resource = CC2520TinyosNetworkC;
  BarePacket = CC2520TinyosNetworkC.BarePacket;
  BareSend = CC2520TinyosNetworkC.Send;
  BareReceive = CC2520TinyosNetworkC.Receive;

  ActiveSend = CC2520TinyosNetworkC.ActiveSend;
  ActiveReceive = CC2520TinyosNetworkC.ActiveReceive;

   // Send Layers
  CC2520TinyosNetworkC.SubSend -> UniqueSendC;
  UniqueSendC.SubSend -> LinkC;
  LinkC.SubSend -> LplC.Send;
  LplC.SubSend -> CsmaC;
  
  // Receive Layers
  CC2520TinyosNetworkC.SubReceive -> LplC;
  LplC.SubReceive -> UniqueReceiveC.Receive;
  UniqueReceiveC.SubReceive ->  CsmaC;
}
