interface Jn516Timer {
  async command error_t init(uint8_t timer_id);
  async command error_t startSingle(uint8_t timer_id, uint16_t duration);
  async command error_t startRepeat(uint8_t timer_id, uint16_t duration);
  async command void stop(uint8_t timer_id);
  async command bool isRunning(uint8_t timer_id);
  async command uint16_t read(uint8_t timer_id);
  async event void fired(uint8_t timer_id);
  async command void clearFiredStatus(uint8_t timer_id);
}
