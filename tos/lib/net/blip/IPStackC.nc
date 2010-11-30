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
 * Routing: determine the next-hop for a packet.  If it needs to be
 * reencapsulated in order to insert a routing header, it should do
 * this as well.  Currently, the routing protocol must also implement
 * a forwarding engine; since the lowest level already queues, this
 * isn't too onerous.  At the bottom, packets come out with a
 * link-local next hop address attached.
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
  SplitControl = IPStackControlP;
  IPStackControlP.StdControl = StdControl;
  IPStackControlP.RoutingControl = RoutingControl;
  IPStackControlP.SubSplitControl -> IPDispatchC;
  
  ForwardingTable = FwdP;
  ForwardingEvents = FwdP;

  /* wiring up of the IP stack */
  IP = IPProtocolsP;            /* top layer - dispatch protocols */
  IPProtocolsP.SubIP -> FwdP.IP; /* routing layer - provision next hops */
  /* this wiring for an 802.15.4 stack */
  FwdP.IPForward[ROUTE_IFACE_154] -> NdC; /* this layer translates L3->L2 addresses */
  NdC.IPLower -> IPDispatchC.IPLower; /* wire to the 6lowpan engine */

  IPRaw = FwdP.IPRaw;

  /* wire in core protocols -- this is only protocol included by default */
  /* it pretty much just replies to pings... */
  components ICMPCoreP, LedsC;
  components IPAddressC, IPPacketP;
  ICMPCoreP.IP -> IPProtocolsP.IP[IANA_ICMP];
  ICMPCoreP.Leds -> LedsC;
  ICMPCoreP.IPAddress -> IPAddressC;

  FwdP.IPAddress -> IPAddressC;
  FwdP.IPPacket -> IPPacketP;
  IPStackControlP.IPAddress -> IPAddressC;

  components new TimerMilliC();
  FwdP.PrintTimer -> TimerMilliC;
  FwdP.Leds -> LedsC;

#ifdef IN6_PREFIX
  components MainC, NoDhcpC;
  NoDhcpC.Boot -> MainC;
  NoDhcpC.IPAddress -> IPAddressC;
#else
  components Dhcp6RelayC;
  components Dhcp6ClientC;
#endif
}
