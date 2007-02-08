configuration AccelReadStreamP
{
  provides {
    interface ReadStream<uint16_t> as ReadStreamX[uint8_t client];
    interface ReadStream<uint16_t> as ReadStreamY[uint8_t client];
  }
  uses {
    interface ReadStream<uint16_t> as ActualX[uint8_t client];
    interface ReadStream<uint16_t> as ActualY[uint8_t client];
  }
}
implementation
{
  enum {
    NACCEL_CLIENTS = uniqueCount(UQ_ACCEL_RESOURCE)
  };
  components AccelConfigP,
    new ArbitratedReadStreamC(NACCEL_CLIENTS, uint16_t) as MultiplexX,
    new ArbitratedReadStreamC(NACCEL_CLIENTS, uint16_t) as MultiplexY;

  ReadStreamX = MultiplexX;
  MultiplexX.Resource -> AccelConfigP;
  MultiplexX.Service = ActualX;

  ReadStreamY = MultiplexY;
  MultiplexY.Resource -> AccelConfigP;
  MultiplexY.Service = ActualY;
}

