configuration HplSam3uUsart0C{
  provides interface HplSam3uUsartControl;
}
implementation{
  components HplSam3uUsart0P as UsartP;
  HplSam3uUsartControl = UsartP.Usart;

  components HplSam3uGeneralIOC, HplSam3uClockC, HplNVICC;
  UsartP.USART_CTS0 -> HplSam3uGeneralIOC.HplPioB8;
  UsartP.USART_RTS0 -> HplSam3uGeneralIOC.HplPioB7;
  UsartP.USART_RXD0 -> HplSam3uGeneralIOC.HplPioA19;
  UsartP.USART_SCK0 -> HplSam3uGeneralIOC.HplPioA17;
  UsartP.USART_TXD0 -> HplSam3uGeneralIOC.HplPioA18;

  UsartP.USARTClockControl0 -> HplSam3uClockC.US0PPCntl;
  UsartP.USARTInterrupt0 -> HplNVICC.US1Interrupt;

  UsartP.ClockConfig -> HplSam3uClockC;

  components McuSleepC;
  UsartP.Usart0InterruptWrapper -> McuSleepC;

  components LedsC;
  UsartP.Leds -> LedsC;

}
