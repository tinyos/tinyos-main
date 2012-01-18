
/**
 * When packets leave a RPL domain, we're need to remove and RPL
 * headers which have been inserted and/or reencapsulate the packet.
 * This component hooks into the forwarding path to do this by
 * converting any RPL TLV options in IPv6 hop-by-hop options header to
 * PadN options.
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 */

#include <lib6lowpan/ip.h>
#include <iprouting.h>
#include <RPL.h>

module RplBorderRouterP {
  uses {
    interface ForwardingEvents;
    interface IPPacket;
  }
} implementation {

  event bool ForwardingEvents.initiate(struct ip6_packet *pkt,
                                       struct in6_addr *next_hop) {
    return TRUE;
  }

  event bool ForwardingEvents.approve(struct ip6_packet *pkt,
                                      struct in6_addr *next_hop) {
    int off;
    uint8_t nxt = IPV6_HOP;
    if (pkt->ip6_inputif == ROUTE_IFACE_PPP)
      return FALSE;

    /* remove any RPL options in the hop-by-hop header by converting
       them to a PadN option */
    off = call IPPacket.findHeader(pkt->ip6_data, pkt->ip6_hdr.ip6_nxt, &nxt);
    if (off < 0) return TRUE;
    call IPPacket.delTLV(pkt->ip6_data, off, RPL_HBH_RANK_TYPE);

    return TRUE;
  }

  event void ForwardingEvents.linkResult(struct in6_addr *dest, struct send_info *info) {

  }
}
