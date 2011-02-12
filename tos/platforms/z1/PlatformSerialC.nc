
configuration PlatformSerialC {
  
  provides interface StdControl;
  provides interface UartStream;
  provides interface UartByte;
  
}

implementation {
  
  components new Msp430Uart0C() as UartC;
  UartStream = UartC;  
  UartByte = UartC;
  
  components Z1SerialP;
  StdControl = Z1SerialP;
  Z1SerialP.Msp430UartConfigure <- UartC.Msp430UartConfigure;
  Z1SerialP.Resource -> UartC.Resource;
  
}
