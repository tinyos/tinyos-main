
module CC2420ReadLqiC {
  provides interface ReadLqi;
  uses interface CC2420Packet;
} implementation {
  command uint8_t ReadLqi.read(message_t *msg) {
    return call CC2420Packet.getLqi(msg);
  }
}
