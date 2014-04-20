module CC2420ReceiveC
{
  provides interface Receive;
  
  uses {
    interface TossimPacketModel as Model;
    interface Packet;
  }
}

implementation
{
  event void Model.receive(message_t* msg)
  {
    uint8_t len = call Packet.payloadLength(msg);
    signal Receive.receive(msg, call Packet.getPayload(msg, len), len);
  }
}
