interface HplMMA7261QTControl
{
  async command void on();
  async command void off();
  async command void gSelect(uint8_t val);
}