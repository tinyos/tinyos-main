configuration PlatformSerialC {
  provides interface Init;
  provides interface StdControl;
  provides interface SerialByteComm;
}
implementation {
  components new Uart1C() as UartC, TelosSerialP;

  Init = UartC;
  StdControl = UartC;
  StdControl = TelosSerialP;
  SerialByteComm = UartC;
  TelosSerialP.Resource -> UartC.Resource;
}
