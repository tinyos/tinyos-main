#include <lib6lowpan/ip.h>

configuration EchoC {
} implementation {
	components MainC, LedsC, EchoP;
	EchoP.Boot -> MainC;
	EchoP.Leds -> LedsC;

	components IPStackC;
	components RPLRoutingC;
	//components StaticIPAddressTosIdC;
	components StaticIPAddressC;
	EchoP.RadioControl -> IPStackC;

	components new UdpSocketC() as Echo;
	EchoP.Echo -> Echo;

	components UDPShellC;
	components RouteCmdC;

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
  // components SerialPrintfC;

  /* This is the alternative printf implementation which puts the
   * output in framed tinyos serial messages.  This lets you operate
   * alongside other users of the tinyos serial stack.
   */
   components PrintfC;
   components SerialStartC;
#endif
}
