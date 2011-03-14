/**
 * HPL for the M16c60 A/D conversion susbsystem.
 *
 * @author Fan Zhang <fanzha@ltu.se>
 *
 */

generic module HplM16c60DacP(uint16_t da_addr,
                              uint8_t da_num)
{
  provides interface HplM16c60Dac;
}
implementation
{
#define da (*TCAST(volatile uint8_t* ONE, da_addr))

  async command void HplM16c60Dac.setValue(uint8_t value)
  {
    da = value;
  }
  
  async command uint8_t HplM16c60Dac.getValue()
  {
    return da;
  }

  async command void HplM16c60Dac.enable()
  {
    SET_BIT(DACON.BYTE, da_num);
  }

  async command void HplM16c60Dac.disable()
  {
    CLR_BIT(DACON.BYTE, da_num);
  }

  async command bool HplM16c60Dac.isEnabled()
  {
    return (READ_BIT(DACON.BYTE, da_num) ? true : false);
  }
}
