#include "CC2420.h"
#include "IEEE802154.h"

configuration CC2420CsmaC
{
  provides interface SplitControl;
  provides interface Send;
  provides interface Receive;
  provides interface RadioBackoff[am_id_t amId];
}

implementation
{
  components CC2420CsmaP as CsmaP;
  components CC2420ControlC;
  components CC2420PacketC;
  components NetworkC as Network;
  components ActiveMessageAddressC as Address;
  components TossimActiveMessageP as AM;
  components SimMoteP;

  RadioBackoff = CsmaP;
  SplitControl = CsmaP;
  Send = CsmaP;
  Receive = CsmaP;

  CsmaP.Model -> Network;
  CsmaP.AMPacket -> AM;
  CsmaP.Packet -> AM;
  CsmaP.CC2420Config -> CC2420ControlC;
  CsmaP.CC2420PacketBody -> CC2420PacketC;
  CsmaP.amAddress -> Address;
  CsmaP.SimMote -> SimMoteP;
}
