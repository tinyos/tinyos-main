
module RF230ReadLqiC {
  provides interface ReadLqi;
  uses interface PacketField<uint8_t> as SubLqi;
} implementation {
  command uint8_t ReadLqi.read(message_t *msg) {
    return call SubLqi.get(msg);
  }
}
