configuration BmaStreamC {
  provides {
    interface ReadStream<bma180_data_t>;
    interface Init;
  }
}
implementation {
  components SpiImpC, BmaStreamP, HplBma180C, LocalTimeMilliC, DiagMsgC, LedsC;

  Init       = BmaStreamP;
  ReadStream = BmaStreamP;

  BmaStreamP.Resource -> SpiImpC.Resource[unique("Atm128SpiC.Resource")];
  BmaStreamP.FastSpiByte -> SpiImpC;
  BmaStreamP.DiagMsg -> DiagMsgC;
  BmaStreamP.Leds -> LedsC;
  BmaStreamP.LocalTime -> LocalTimeMilliC;
  BmaStreamP.CSN -> HplBma180C.CSN;
  BmaStreamP.PWR -> HplBma180C.PWR;
  BmaStreamP.Interrupt -> HplBma180C.ACCINT;
}
