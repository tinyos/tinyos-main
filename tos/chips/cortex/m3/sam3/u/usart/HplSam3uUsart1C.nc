configuration HplSam3uUsart1C{
  provides interface HplSam3uUsartControl;
}
implementation{
  components HplSam3uUsart1P as UsartP;
  HplSam3uUsartControl = UsartP.Usart;


  components HplSam3uGeneralIOC, HplSam3uClockC, HplNVICC;

  UsartP.USART_CTS1 -> HplSam3uGeneralIOC.HplPioA23;
  UsartP.USART_RTS1 -> HplSam3uGeneralIOC.HplPioA22;
  UsartP.USART_RXD1 -> HplSam3uGeneralIOC.HplPioA21;
  UsartP.USART_SCK1 -> HplSam3uGeneralIOC.HplPioA24;
  UsartP.USART_TXD1 -> HplSam3uGeneralIOC.HplPioA20;

  UsartP.USARTClockControl1 -> HplSam3uClockC.US1PPCntl;
  UsartP.USARTInterrupt1 -> HplNVICC.US1Interrupt;

  UsartP.ClockConfig -> HplSam3uClockC;

  components McuSleepC;
  UsartP.Usart1InterruptWrapper -> McuSleepC;

  components LedsC;
  UsartP.Leds -> LedsC;

}
