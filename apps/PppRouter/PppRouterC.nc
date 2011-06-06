#include "ppp.h"

configuration PppRouterC {
} implementation {
  components PppRouterP;

  components MainC;
  PppRouterP.Boot -> MainC;

  components LedC;
  PppRouterP.MultiLed -> LedC;

  components PppDaemonC;
  PppRouterP.Ppp -> PppDaemonC;

  components PppIpv6C;
  PppDaemonC.PppProtocol[PppIpv6C.ControlProtocol] -> PppIpv6C.PppControlProtocol;
  PppDaemonC.PppProtocol[PppIpv6C.Protocol] -> PppIpv6C.PppProtocol;
  PppIpv6C.Ppp -> PppDaemonC;
  PppIpv6C.LowerLcpAutomaton -> PppDaemonC;
  PppRouterP.Ipv6LcpAutomaton -> PppIpv6C;
  PppRouterP.PppIpv6 -> PppIpv6C;

  components PlatformSerialHdlcUartC;
  PppDaemonC.HdlcUart -> PlatformSerialHdlcUartC;
  PppDaemonC.UartControl -> PlatformSerialHdlcUartC;

  components PppPrintfC, PppC;;
  PppPrintfC.Ppp -> PppDaemonC;
  PppDaemonC.PppProtocol[PppPrintfC.Protocol] -> PppPrintfC;
  PppPrintfC.Ppp -> PppC;

  components IPStackC, IPForwardingEngineP;
  IPForwardingEngineP.IPForward[ROUTE_IFACE_PPP] -> PppRouterP.IPForward;
  PppRouterP.IPControl -> IPStackC;
  PppRouterP.ForwardingTable -> IPStackC;

#ifdef RPL_ROUTING
  components RPLRoutingC;
  PppRouterP.RootControl -> RPLRoutingC;
#endif

  // UDP shell on port 2000
  // components UDPShellC;

  // prints the routing table
  // components RouteCmdC;

#ifndef IN6_PREFIX
  components Dhcp6ClientC;
  PppRouterP.Dhcp6Info -> Dhcp6ClientC;
#endif
}
