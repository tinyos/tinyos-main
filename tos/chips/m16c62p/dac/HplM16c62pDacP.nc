/**
 * HPL for the M16c62p A/D conversion susbsystem.
 *
 * @author Fan Zhang <fanzha@ltu.se>
 *
 */

generic module HplM16c62pDacP(uint16_t da_addr,
                              uint8_t da_num)
{
  provides interface HplM16c62pDac;
}
implementation
{
#define da (*TCAST(volatile uint8_t* ONE, da_addr))

  async command void HplM16c62pDac.setValue(uint8_t value)
  {
    da = value;
  }
  
  async command uint8_t HplM16c62pDac.getValue()
  {
    return da;
  }

  async command void HplM16c62pDac.enable()
  {
    SET_BIT(DACON.BYTE, da_num);
  }

  async command void HplM16c62pDac.disable()
  {
    CLR_BIT(DACON.BYTE, da_num);
  }

  async command bool HplM16c62pDac.isEnabled()
  {
    return (READ_BIT(DACON.BYTE, da_num) ? true : false);
  }
}
