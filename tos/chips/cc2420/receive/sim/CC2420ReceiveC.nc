configuration CC2420ReceiveC
{
  provides interface Receive;
}

implementation
{
  components CC2420ReceiveP;
  components TossimActiveMessageP as AM, TossimPacketModelC as Network;
  Receive = CC2420ReceiveP;

  CC2420ReceiveP.Packet -> AM;
  CC2420ReceiveP.Model -> Network.Packet;
}
