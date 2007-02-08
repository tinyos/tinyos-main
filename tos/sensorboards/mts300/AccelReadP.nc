configuration AccelReadP
{
  provides {
    interface Read<uint16_t> as ReadX[uint8_t client];
    interface Read<uint16_t> as ReadY[uint8_t client];
  }
}
implementation
{
  components AccelConfigP,
    new MultiplexedReadC(uint16_t) as MultiplexX,
    new MultiplexedReadC(uint16_t) as MultiplexY,
    new AdcReadClientC() as AdcX,
    new AdcReadClientC() as AdcY;

  ReadX = MultiplexX;
  MultiplexX.Resource -> AccelConfigP;
  MultiplexX.Service -> AdcX;
  AdcX.Atm128AdcConfig -> AccelConfigP.ConfigX;

  ReadY = MultiplexY;
  MultiplexY.Resource -> AccelConfigP;
  MultiplexY.Service -> AdcY;
  AdcY.Atm128AdcConfig -> AccelConfigP.ConfigY;
}

