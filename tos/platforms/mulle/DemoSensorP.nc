module DemoSensorP
{
  provides interface M16c60AdcConfig;
  provides interface Init;

  uses interface GeneralIO as Pin;
  uses interface GeneralIO as AVcc;
}
implementation
{
  command error_t Init.init()
  {
    call Pin.makeInput();
    // TODO(henrik) This Vref should be turned on in connection to the A/D
    // converter code and not here.
    // Turn on the Vref
    call AVcc.makeOutput();
    call AVcc.set();
  }

  async command uint8_t M16c60AdcConfig.getChannel()
  {
    // select the AN0 = P10_0 to potentiometer on the expansion board.
    return M16c60_ADC_CHL_AN0;
  }

  async command uint8_t M16c60AdcConfig.getPrecision()
  {
    return M16c60_ADC_PRECISION_10BIT;
  }

  async command uint8_t M16c60AdcConfig.getPrescaler()
  {
    return M16c60_ADC_PRESCALE_4;
  }
}
