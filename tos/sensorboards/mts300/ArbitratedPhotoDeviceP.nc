configuration ArbitratedPhotoDeviceP
{
  provides interface Read<uint16_t>[uint8_t client];
}
implementation
{
  components PhotoTempDeviceC,
    new ArbitratedReadC(uint16_t) as ArbitrateRead;

  Read = ArbitrateRead;
  ArbitrateRead.Service -> PhotoTempDeviceC.ReadPhoto;
  ArbitrateRead.Resource -> PhotoTempDeviceC.PhotoResource;
}
