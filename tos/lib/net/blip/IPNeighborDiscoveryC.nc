/*
 * Neighbor Discovery for blip
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration IPNeighborDiscoveryC {
  provides {
    interface NeighborDiscovery;
    interface IPForward;
    interface StdControl;
  }
  uses {
    interface IPLower;
  }
} implementation {
  components IPNeighborDiscoveryP, IPAddressC, Ieee154AddressC;
  components IPForwardingEngineP;
  components new ICMPCodeDispatchC(ICMP_TYPE_ROUTER_SOL) as ICMP_RS;
  components new ICMPCodeDispatchC(ICMP_TYPE_ROUTER_ADV) as ICMP_RA;
  components new ICMPCodeDispatchC(ICMP_TYPE_NEIGHBOR_SOL) as ICMP_NS;
  components new ICMPCodeDispatchC(ICMP_TYPE_NEIGHBOR_ADV) as ICMP_NA;
  components RandomC;
  components new TimerMilliC() as RSTimer;

  NeighborDiscovery = IPNeighborDiscoveryP.NeighborDiscovery;
  IPForward = IPNeighborDiscoveryP.IPForward;
  StdControl = IPNeighborDiscoveryP.StdControl;

  IPNeighborDiscoveryP.IP_RS -> ICMP_RS.IP[ICMPV6_CODE_RS];
  IPNeighborDiscoveryP.IP_RA -> ICMP_RA.IP[ICMPV6_CODE_RA];
  IPNeighborDiscoveryP.IP_NS -> ICMP_NS.IP[ICMPV6_CODE_NS];
  IPNeighborDiscoveryP.IP_NA -> ICMP_NA.IP[ICMPV6_CODE_NA];
  IPNeighborDiscoveryP.RSTimer -> RSTimer.Timer;
  IPNeighborDiscoveryP.Random -> RandomC.Random;
  IPNeighborDiscoveryP.ForwardingTable -> IPForwardingEngineP.ForwardingTable;
  IPNeighborDiscoveryP.IPLower = IPLower;
  IPNeighborDiscoveryP.IPAddress -> IPAddressC.IPAddress;
  IPNeighborDiscoveryP.Ieee154Address -> Ieee154AddressC.Ieee154Address;

#if BLIP_ADDR_AUTOCONF
  // If we are using router advertisements to set our prefix and global address
  // then wire in the addressing components.
  components LocalIeeeEui64C;
  IPNeighborDiscoveryP.SetIPAddress -> IPAddressC.SetIPAddress;
  IPNeighborDiscoveryP.LocalIeeeEui64 -> LocalIeeeEui64C.LocalIeeeEui64;
#endif
}
