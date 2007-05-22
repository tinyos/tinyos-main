/**
 * Battery Voltage. The returned value represents the difference
 * between the battery voltage and V_BG (1.23V). The formula to convert
 * it to mV is: 1223 * 1024 / value.
 *
 * @author Razvan Musaloiu-E.
 */

generic configuration VoltageC()
{
  provides interface Read<uint16_t>;
}

implementation
{
  components new AdcReadClientC(), VoltageP;

  Read = AdcReadClientC;

  AdcReadClientC.Atm128AdcConfig -> VoltageP;
}
