
uint16_t adjustLQI(uint8_t val) {
  uint16_t result = 64 - (val / 4);
  result = (((result * result) >> 3) * result) >> 3;  // result = (result ^ 3) / 64
  return result;
}

module RF230ReadLqiC {
  provides interface ReadLqi;
  uses interface PacketField<uint8_t> as SubLqi;
} implementation {
  command uint8_t ReadLqi.read(message_t *msg) {
    return call SubLqi.get(msg);
  }
}
