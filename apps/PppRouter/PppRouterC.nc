
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

  // SDH : don't bother including the PppPrintfC by default
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

  // UDP shell on port 2000
  components UDPShellC;

  // prints the routing table
  components RouteCmdC;

#ifndef IN6_PREFIX
  components Dhcp6ClientC;
  PppRouterP.Dhcp6Info -> Dhcp6ClientC;
#endif
}
