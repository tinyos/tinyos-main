#include <jendefs.h>

configuration PlatformSerialC {
  provides interface StdControl;
  provides interface UartByte;
  provides interface UartStream;
}
implementation {
  components Jn516Uart0C as Uart0;
  StdControl = Uart0;
  UartStream = Uart0;
  UartByte = Uart0;

  components Counter32khz32C as Counter;
  Uart0.Counter -> Counter;
}
