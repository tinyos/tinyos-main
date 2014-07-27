/**
 * Wire together the IP stack
 *
 * To make it somewhat flexible, the stack consists of four main
 * layers: Protocol, Routing, NeighborDiscovery, and Dispatch.  This
 * component wires them together.
 *
 * Protocol: dispatch based on the final next header value in an
 * ipv6_packet.
 *
 * Routing: determine the next-hop for a packet as a link-local
 * address.  This is accomplished by looking up the destination
 * address in the forwarding table.
 *
 * NeighborDiscovery: responsible for address resolution.  Very
 * simple, since only link-local addresses are considered to be
 * on-link.
 *
 * Dispatch: okay, this one's badly named.  It's the 6lowpan engine
 * which talks to a packet radio on the bottom and presents fully
 * reassembled and decompressed IPv6 packets on top.  This means most
 * of the stack can ignore the fact that there's all this magic going
 * on.
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 */
#include <iprouting.h>

configuration IPStackC {
  provides {
    interface SplitControl;
    interface IP[uint8_t nxt_hdr];
    interface IP as IPRaw;
    interface ForwardingTable;
    interface ForwardingTableEvents;
    interface ForwardingEvents[uint8_t ifindex];
  }
  uses {
    /* provided to stack components to turn themselves on and off */
    interface StdControl;
    interface StdControl as RoutingControl;
  }
} implementation {

  components IPProtocolsP,
    IPForwardingEngineP as FwdP,
    IPNeighborDiscoveryC as NdC,
    IPDispatchC;
  components IPStackControlP;
  SplitControl = IPStackControlP.SplitControl;
  IPStackControlP.StdControl = StdControl;
  IPStackControlP.RoutingControl = RoutingControl;
  IPStackControlP.SubSplitControl -> IPDispatchC;
  IPStackControlP.NeighborDiscoveryControl -> NdC.StdControl;

  ForwardingTable = FwdP.ForwardingTable;
  ForwardingTableEvents = FwdP.ForwardingTableEvents;
  ForwardingEvents = FwdP.ForwardingEvents;

  /* wiring up of the IP stack */
  IP = IPProtocolsP.IP;          /* top layer - dispatch protocols */
  IPProtocolsP.SubIP -> FwdP.IP; /* routing layer - provision next hops */
  /* this wiring for an 802.15.4 stack */
  FwdP.IPForward[ROUTE_IFACE_154] -> NdC.IPForward; /* this layer translates
                                                     * L3->L2 addresses */
  NdC.IPLower -> IPDispatchC.IPLower; /* wire to the 6lowpan engine */
  IPRaw = FwdP.IPRaw;

  /* Wire in core protocols.
   * ICMP is only protocol included by default. It pretty much just replies to
   * pings. */
  components ICMPCoreP;
  ICMPCoreP.IP -> IPProtocolsP.IP[IANA_ICMP];

  /* Connect the address and packet helper components. */
  components IPAddressC, IPPacketC;
  ICMPCoreP.IPAddress -> IPAddressC.IPAddress;
  FwdP.IPAddress -> IPAddressC.IPAddress;
  FwdP.IPPacket -> IPPacketC.IPPacket;
  IPProtocolsP.IPPacket -> IPPacketC.IPPacket;
  IPStackControlP.IPAddress -> IPAddressC.IPAddress;

  components new PoolC(struct in6_iid, N_CONCURRENT_SENDS) as FwdAddrPoolC;
  FwdP.Pool -> FwdAddrPoolC;

#ifdef PRINTFUART_ENABLED
  components new TimerMilliC();
  FwdP.PrintTimer -> TimerMilliC.Timer;
#endif

#ifdef DELUGE
  components NWProgC;
#endif

}
