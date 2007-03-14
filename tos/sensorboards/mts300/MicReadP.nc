configuration MicReadP
{
  provides 
  {
    interface Read<uint16_t>[uint8_t client];
  }
  uses
  {
    interface Read<uint16_t> as ActualRead[uint8_t client];
  }
}
implementation
{
  components MicDeviceP,
  new ArbitratedReadC(uint16_t);

  Read = ArbitratedReadC;
  ArbitratedReadC.Resource -> MicDeviceP;
  ArbitratedReadC.Service = ActualRead;
}

