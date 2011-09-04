configuration ArbitratedInternalTempDeviceP {
  provides interface Read<uint16_t>[uint8_t consumer];
}
implementation {
  components Atm128InternalTempDeviceC,
  new ArbitratedReadC(uint16_t) as ArbRead;

  Read = ArbRead;
  ArbRead.Service  -> Atm128InternalTempDeviceC.ReadTemp;
  ArbRead.Resource -> Atm128InternalTempDeviceC.ResourceTemp;
}
