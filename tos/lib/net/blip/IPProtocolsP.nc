
#include <lib6lowpan/iovec.h>
#include <lib6lowpan/ip.h>

#include "blip_printf.h"

module IPProtocolsP {
  provides {
    interface IP[uint8_t nxt_hdr];
  }
  uses {
    interface IPAddress;
    interface IP as SubIP;
    interface IPPacket;
  }
} implementation {

  event void SubIP.recv(struct ip6_hdr *iph, 
                        void *payload, 
                        size_t len, 
                        struct ip6_metadata *meta) {
    int payload_off;
    uint8_t nxt_hdr;
    struct ip_iovec v = {
      .iov_base = payload,
      .iov_len = len,
      .iov_next = NULL,
    };

    // Check whether the packet has a fragment extension header indicating
    // actual fragmentation. If so, discard --- we don't handle fragmentation,
    // and delivering fragments as complete packets is not really a good idea...
    nxt_hdr=IPV6_FRAG;
    payload_off = call IPPacket.findHeader(&v, iph->ip6_nxt, &nxt_hdr);
    if (payload_off>=0 && ((uint16_t*)((uint8_t*)payload+payload_off))[1]!=0)
      return;

    // find the transport header and deliver -- nxt_hdr is updated by findHeader
    nxt_hdr=IP6PKT_TRANSPORT;
    payload_off = call IPPacket.findHeader(&v, iph->ip6_nxt, &nxt_hdr);
    printf("IPProtocols - deliver -- off: %i\n", payload_off);
    if (payload_off >= 0) {
      signal IP.recv[nxt_hdr](iph, ((uint8_t *)payload) + payload_off, 
                              len - payload_off, meta);
    }
  }

  command error_t IP.send[uint8_t nxt_hdr](struct ip6_packet *msg) {
    msg->ip6_hdr.ip6_vfc = IPV6_VERSION;
    msg->ip6_hdr.ip6_hops = 16;
    printf("IP Protocol send - nxt_hdr: %i iov_len: %i plen: %u\n", 
               nxt_hdr, iov_len(msg->ip6_data), ntohs(msg->ip6_hdr.ip6_plen));
    return call SubIP.send(msg);
  }

  default event void IP.recv[uint8_t nxt_hdr](struct ip6_hdr *iph, void *payload, 
                                              size_t len, struct ip6_metadata *meta) {}
  event void IPAddress.changed(bool global_valid) {}
}
