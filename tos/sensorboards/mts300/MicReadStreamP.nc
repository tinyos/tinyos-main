configuration MicReadStreamP
{
  provides 
  {
    interface MicSetting;
    interface ReadStream<uint16_t>[uint8_t client];
  }
  uses
  {
    interface ReadStream<uint16_t> as ActualRead[uint8_t client];
  }
}
implementation
{
  enum {
    NMIC_CLIENTS = uniqueCount(UQ_MIC_RESOURCE)
  };
  components MicDeviceP,
  new ArbitratedReadStreamC(NMIC_CLIENTS, uint16_t);

  MicSetting = MicDeviceP;

  ReadStream = ArbitratedReadStreamC;
  ArbitratedReadStreamC.Resource -> MicDeviceP;
  ArbitratedReadStreamC.Service = ActualRead;
}

