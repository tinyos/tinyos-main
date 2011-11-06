
uint16_t adjustLQI(uint8_t val) {
  uint16_t result = (80 - (val - 50));
  result = (((result * result) >> 3) * result) >> 3;  // result = (result ^ 3) / 64
  return result;
}

module CC2420ReadLqiC {
  provides interface ReadLqi;
  uses interface CC2420Packet;
} implementation {
  command uint8_t ReadLqi.readLqi(message_t *msg) {
    return call CC2420Packet.getLqi(msg);
  }

  command uint8_t ReadLqi.readRssi(message_t *msg) {
    return call CC2420Packet.getRssi(msg);
  }
}
