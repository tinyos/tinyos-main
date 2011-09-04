generic configuration InternalTempStreamC() {
  provides interface Readstream<uint16_t>;
}
implementation {
  components TempDeviceP, new AdcReadStreamClientC();

  AdcReadStreamClientC.Atm128AdcConfig -> TempDeviceP;
}
