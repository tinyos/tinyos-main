/**
 * Battery Voltage. The returned value represents the difference
 * between the battery voltage and V_BG (1.23V). The formula to convert
 * it to mV is: 1223 * 1024 / value.
 *
 * @author Razvan Musaloiu-E.
 */
module VoltageP
{
  provides interface Atm128AdcConfig;
}
implementation
{
  async command uint8_t Atm128AdcConfig.getChannel()
  {
    // select the 1.23V (V_BG). Reference: Table 97, page 244 from the Atmega128
    return ATM128_ADC_SNGL_1_23;
  }

  async command uint8_t Atm128AdcConfig.getRefVoltage()
  {
    return ATM128_ADC_VREF_OFF;
  }

  async command uint8_t Atm128AdcConfig.getPrescaler()
  {
    return ATM128_ADC_PRESCALE;
  }
}
