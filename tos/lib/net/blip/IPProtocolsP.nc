
#include <lib6lowpan/ip.h>

#include "blip_printf.h"

module IPProtocolsP {
  provides {
    interface IP[uint8_t nxt_hdr];
  }
  uses {
    interface IPAddress;
    interface IP as SubIP;
  }
} implementation {

  event void SubIP.recv(struct ip6_hdr *iph, 
                        void *payload, 
                        size_t len, 
                        struct ip6_metadata *meta) {
    struct ip6_ext *cur = (struct ip6_ext *)(iph + 1);
    uint8_t nxt = iph->ip6_nxt;

    while (nxt == IPV6_HOP  || nxt == IPV6_ROUTING  || nxt == IPV6_FRAG ||
           nxt == IPV6_DEST || nxt == IPV6_MOBILITY || nxt == IPV6_IPV6) {
      nxt = cur->ip6e_nxt;
      cur = (struct ip6_ext *)((uint8_t *)cur + cur->ip6e_len);
    }

    len -= POINTER_DIFF(cur, payload);
    signal IP.recv[nxt](iph, cur, len, meta);
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
