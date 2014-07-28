interface BigCrc {
  command error_t computeCrc(void* buf, uint16_t len);
  event void computeCrcDone(void* buf, uint16_t len, uint16_t crc, error_t error);
}
