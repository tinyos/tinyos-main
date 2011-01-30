configuration HplSam3uUsart2C{
  provides interface HplSam3uUsartControl;
}
implementation{
  components HplSam3uUsart2P as UsartP;
  HplSam3uUsartControl = UsartP.Usart;


  components HplSam3uGeneralIOC, HplSam3uClockC, HplNVICC;

  UsartP.USART_CTS2 -> HplSam3uGeneralIOC.HplPioB22;
  UsartP.USART_RTS2 -> HplSam3uGeneralIOC.HplPioB21;
  UsartP.USART_RXD2 -> HplSam3uGeneralIOC.HplPioA23;
  UsartP.USART_SCK2 -> HplSam3uGeneralIOC.HplPioA25;
  UsartP.USART_TXD2 -> HplSam3uGeneralIOC.HplPioA22;

  UsartP.USARTClockControl2 -> HplSam3uClockC.US2PPCntl;
  UsartP.USARTInterrupt2 -> HplNVICC.US1Interrupt;

  UsartP.ClockConfig -> HplSam3uClockC;

  components McuSleepC;
  UsartP.Usart2InterruptWrapper -> McuSleepC;

  components LedsC;
  UsartP.Leds -> LedsC;

}
