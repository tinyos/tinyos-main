#include "Atm128Adc.h"
/**
  *
  * @author Zsolt Szabó <szabomeister@gmail.com>
  */

module InternalTempP {
  provides interface Atm128AdcConfig;
}
implementation {
  async command uint8_t Atm128AdcConfig.getChannel() {
    return ATM128_ADC_INT_TEMP;
  }

  async command uint8_t Atm128AdcConfig.getRefVoltage() {
    return ATM128_ADC_VREF_1_6;
  }

  async command uint8_t Atm128AdcConfig.getPrescaler() {
    return ATM128_ADC_PRESCALE_32;
  }
}
