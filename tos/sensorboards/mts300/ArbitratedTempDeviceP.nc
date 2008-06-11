configuration ArbitratedTempDeviceP
{
  provides interface Read<uint16_t>[uint8_t client];
}
implementation
{
  components PhotoTempDeviceC,
    new ArbitratedReadC(uint16_t) as ArbitrateRead;

  Read = ArbitrateRead;
  ArbitrateRead.Service -> PhotoTempDeviceC.ReadTemp;
  ArbitrateRead.Resource -> PhotoTempDeviceC.TempResource;
}
