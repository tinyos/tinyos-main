configuration PlatformSerialC {
  provides interface Init;
  provides interface StdControl;
  provides interface SerialByteComm;
}
implementation {
  components new Uart1C() as UartC, TinyNodeSerialP;

  Init = UartC;
  StdControl = UartC;
  StdControl = TinyNodeSerialP;
  SerialByteComm = UartC;
  TinyNodeSerialP.Resource -> UartC.Resource;
}
