#include "IEEE802154.h"
#include "message.h"
#include "CC2420.h"
#include "CC2420TimeSyncMessage.h"




configuration CC2420PacketC
{
  provides {
    interface CC2420Packet;
    interface PacketAcknowledgements as Acks;
    interface CC2420PacketBody;
    interface LinkPacketMetadata;
  }
}

implementation
{
  components TossimPacketModelC as Network;
  Acks = Network;
  LinkPacketMetadata   = CC2420PacketP;

  components CC2420PacketP;
  CC2420Packet = CC2420PacketP;
  CC2420PacketBody = CC2420PacketP;
}
