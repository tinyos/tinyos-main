configuration TempDeviceP {
  provides interface Atm128AdcConfig;
}
implementation {
  components TempP;

  Atm128AdcConfig = TempP;
}
