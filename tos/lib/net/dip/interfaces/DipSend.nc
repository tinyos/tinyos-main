
interface DipSend {
  command error_t send(uint8_t len);
  command void* getPayloadPtr();
  command uint8_t maxPayloadLength();
}
