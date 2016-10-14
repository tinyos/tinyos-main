
#include <iprouting.h>

#include "ppp.h"

configuration PppRouterC {
} implementation {
  components PppRouterP;

  components MainC;
  PppRouterP.Boot -> MainC;



  components LedsC as LedsC;
  PppRouterP.Leds -> LedsC;

  components PppDaemonC;
  PppRouterP.PppControl -> PppDaemonC;

  components PppIpv6C;
  PppDaemonC.PppProtocol[PppIpv6C.ControlProtocol] -> PppIpv6C.PppControlProtocol;
  PppDaemonC.PppProtocol[PppIpv6C.Protocol] -> PppIpv6C.PppProtocol;
  PppIpv6C.Ppp -> PppDaemonC;
  PppIpv6C.LowerLcpAutomaton -> PppDaemonC;

  PppRouterP.Ipv6LcpAutomaton -> PppIpv6C;
  PppRouterP.PppIpv6 -> PppIpv6C;
  PppRouterP.Ppp -> PppDaemonC;

#if defined(PLATFORM_TELOSB) || defined(PLATFORM_EPIC)
  components PlatformHdlcUartC as HdlcUartC;
#else
  components DefaultHdlcUartC as HdlcUartC;
#endif
  PppDaemonC.HdlcUart -> HdlcUartC;
  PppDaemonC.UartControl -> HdlcUartC;

  // components SerialPrintfC;
  // // SDH : don't bother including the PppPrintfC by default
  // components PppPrintfC, PppC;;
  // PppPrintfC.Ppp -> PppDaemonC;
  // PppDaemonC.PppProtocol[PppPrintfC.Protocol] -> PppPrintfC;
  // PppPrintfC.Ppp -> PppC;

  components IPStackC, IPForwardingEngineP, IPPacketC;
  IPForwardingEngineP.IPForward[ROUTE_IFACE_PPP] -> PppRouterP.IPForward;
  PppRouterP.IPControl -> IPStackC;
  PppRouterP.ForwardingTable -> IPStackC;
  PppRouterP.IPPacket -> IPPacketC;

#ifdef RPL_ROUTING
  components RPLRoutingC, RplBorderRouterP;
  PppRouterP.RootControl -> RPLRoutingC;
  RplBorderRouterP.ForwardingEvents -> IPStackC.ForwardingEvents[ROUTE_IFACE_PPP];
  RplBorderRouterP.IPPacket -> IPPacketC;
#endif

#ifndef TARGET_PLATFORM_TELOSB //telosb just hasn't enough memory
  // UDP shell on port 2000
  components UDPShellC;

  // prints the routing table
   components RouteCmdC;
#endif

#ifdef IN6_PREFIX
  // components StaticIPAddressTosIdC; // Use TOS_NODE_ID in address
	 components StaticIPAddressC; // Use LocalIeee154 in address
#else
  components Dhcp6C;
  components Dhcp6ClientC;
  PppRouterP.Dhcp6Info -> Dhcp6ClientC;
#endif

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
  components SerialPrintfC;

  /* This is the alternative printf implementation which puts the
   * output in framed tinyos serial messages.  This lets you operate
   * alongside other users of the tinyos serial stack.
   */
//   components PrintfC;
//   components SerialStartC;
#endif
}
