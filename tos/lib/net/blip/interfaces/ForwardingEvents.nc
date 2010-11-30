
#include <iprouting.h>
#include <IPDispatch.h>

interface ForwardingEvents {
  /**
   * Signaled when initiating a new flow (not forwarding).
   *
   * This allows higher-layer components to modify the payload or
   * insert new headers before the packet is sent.
   */
  event bool initiate(struct ip6_packet *pkt,
                      struct in6_addr *next_hop);

  /**
   * Signaled for each packet being forwarded.
   *
   * For datapath validation.  Allows the routing protocol to look at
   * a packet as it flows through.  If the event returns FALSE the
   * packet is dropped.  The routing protocol may change fields in the
   * packet header such as the flow label.
   *
   * @iph the ipv6 header of the packet
   * @rhdr a routing header in the packet, or NULL if not present
   * @next_hop the ipv6 address of the next hop, as determined by the 
         forwarding engine.
   */
  event bool approve(struct ip6_hdr *iph, 
                     struct ip6_route *rhdr,
                     struct in6_addr *next_hop);

  /**
   * Signaled once per link frame sent to an address in the routing table.
   *
   * (isn't signaled for packets which don't have an entry in the
   * routing table.)  Allows a higher-level component to maintain
   * statistics on the link behavior of their routes.
   */
  event void linkResult(struct in6_addr *dest, struct send_info *info);
}
