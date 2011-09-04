generic configuration ITempC() {
  provides interface Read<uint16_t>;
}
implementation {
  components new AdcReadClientC();
  Read = AdcReadClientC;

  components ITempP;
  AdcReadClientC.Atm128AdcConfig -> ITempP;
}
