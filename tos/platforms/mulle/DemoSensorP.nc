module DemoSensorP
{
  provides interface M16c62pAdcConfig;
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

  async command uint8_t M16c62pAdcConfig.getChannel()
  {
    // select the AN0 = P10_0 to potentiometer on the expansion board.
    return M16c62p_ADC_CHL_AN0;
  }

  async command uint8_t M16c62pAdcConfig.getPrecision()
  {
    return M16c62p_ADC_PRECISION_10BIT;
  }

  async command uint8_t M16c62pAdcConfig.getPrescaler()
  {
    return M16c62p_ADC_PRESCALE_4;
  }
}
