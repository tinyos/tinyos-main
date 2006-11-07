configuration PlatformSerialC {
  provides interface StdControl;
  provides interface UartStream;
}

implementation {
  components new Msp430Uart1C() as UartC;
  UartStream = UartC;

  components TinyNodeSerialP;
  StdControl = TinyNodeSerialP;
  TinyNodeSerialP.Msp430UartConfigure <- UartC.Msp430UartConfigure;
  TinyNodeSerialP.Resource -> UartC.Resource;
}

