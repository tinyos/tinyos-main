#include <iprouting.h>

configuration CoapBlipC {

} implementation {
  components MainC;
  components LedsC;
  components CoapBlipP as App;
  components IPStackC;
//  components UDPShellC;

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.RadioControl ->  IPStackC;

#ifdef IN6_PREFIX
// components StaticIPAddressTosIdC;
 components StaticIPAddressC;
#endif

#ifdef RPL_ROUTING
  components RPLRoutingC;
#endif

  components CoapServerC;

#ifdef PRINTFUART_ENABLED
  /* This component wires printf directly to the serial port, and does
   * not use any framing.  You can view the output simply by tailing
   * the serial device.  Unlike the old printfUART, this allows us to
   * use PlatformSerialC to provide the serial driver.
   *
   * For instance:
   * $ stty -F /dev/ttyUSB0 115200
   * $ tail -f /dev/ttyUSB0
  */
  //components SerialPrintfC;

  /* This is the alternative printf implementation which puts the
   * output in framed tinyos serial messages.  This lets you operate
   * alongside other users of the tinyos serial stack.
   */
  components PrintfC;
  components SerialStartC;
#endif
}
