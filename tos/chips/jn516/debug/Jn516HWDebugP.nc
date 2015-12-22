/**
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 */
#include "PeripheralRegs.h"

module Jn516HWDebugP {
  provides {
    interface Jn516HWDebug;
  }
  uses {
    interface Boot;
  }
} implementation {
  // initialize requested HWDebug facilities
  event void Boot.booted()
  {
#ifdef JN516_HWDEBUG_RADIO_RXTX_PINS
    call Jn516HWDebug.enableRadioHighPowerRxTxPins();
#endif
#ifdef JN516_HWDEBUG_RADIO_CHIPTEST_PINS
    call Jn516HWDebug.enableRadioChipTestPins();
#endif
  }

  /** 
   * Enable RX/TX pin toggling in the radios high power mode.
   *
   * DIO2 is high during RX
   * DIO3 is high during TX
   */
  async command void Jn516HWDebug.enableRadioHighPowerRxTxPins() {
    vREG_SysWrite(REG_SYS_PWR_CTRL,
        u32REG_SysRead(REG_SYS_PWR_CTRL)
            | REG_SYSCTRL_PWRCTRL_RFRXEN_MASK
            | REG_SYSCTRL_PWRCTRL_RFTXEN_MASK);
  }

  /** 
   * Disable RX/TX pin toggling in the radios high power mode.
   */
  async command void Jn516HWDebug.disableRadioHighPowerRxTxPins() {
    vREG_SysWrite(REG_SYS_PWR_CTRL,
        u32REG_SysRead(REG_SYS_PWR_CTRL)
            & ~(REG_SYSCTRL_PWRCTRL_RFRXEN_MASK | REG_SYSCTRL_PWRCTRL_RFTXEN_MASK));
  }

  /**
   * Check whether the radio high power RX/TX pin toggling is enabled
   *
   * @returns TRUE If enabled
   *          FALSE Otherwise
   */
  async command bool Jn516HWDebug.getStateRadioHighPowerRxTxPins() {
    uint32_t reg = u32REG_SysRead(REG_SYS_PWR_CTRL);
    if (reg & (REG_SYSCTRL_PWRCTRL_RFRXEN_MASK | REG_SYSCTRL_PWRCTRL_RFTXEN_MASK))
	  return TRUE;
	else
	  return FALSE;
  }

  /** 
   * Enable several pins to debug the radio state.
   *
   * DIO0      in_packet    Receiving a packet. (Probably after SFD)
   * DIO2      rx_sig       Incomoing IF (intermediate frequency) signal
   * DIO4:3    rx_gain      Internal receiver gain setting
   *                        0=13dB, 1=33dB, 2=61dB
   * DIO5      rx_rssi_en   Controls when RSSI measurements should be taken
   * DIO10:8   rx_adc_sel   Selects tap point for RSSI measurement
   * DIO13:11  rx_adc_rssi  RSSI value
   * DIO14     phy_on       Radio on/off indication
   * DIO15     phy_dir      Radio TX/RX indication
   * DIO16     phy_ready    PHY ready to TX or RX
   * DIO17     clk_16m      16MHz clock
   */
  async command void Jn516HWDebug.enableRadioChipTestPins() {
  vREG_SysWrite(REG_SYS_PWR_CTRL,
      u32REG_SysRead(REG_SYS_PWR_CTRL)
          | (1UL << 26));
  }

  /** 
   * Disable several pins to debug the radio state.
   */
  async command void Jn516HWDebug.disableRadioChipTestPins() {
  vREG_SysWrite(REG_SYS_PWR_CTRL,
      u32REG_SysRead(REG_SYS_PWR_CTRL)
          & ~(1UL << 26));
  }

  /**
   * Check whether the radio debug pins are enabled
   *
   * @returns TRUE If enabled
   *          FALSE Otherwise
   */
  async command bool Jn516HWDebug.getStateRadioChipTestPins() {
    uint32_t reg = u32REG_SysRead(REG_SYS_PWR_CTRL);
    if (reg & (1UL << 26))
	  return TRUE;
	else
	  return FALSE;
  }
}
