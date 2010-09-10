
/** 
 *
 * This module implements core ICMP functionality, like replying to
 * echo requests and sending time exceeded messages.  Other modules
 * which want to implement other functionality can wire to the IP
 * interface.
 *
 */
#include <ip.h>

module ICMPCoreP {
  provides interface IP as ICMP_IP[uint8_t type];
  uses interface IP;
} implementation {
void iov_print(struct ip_iovec *iov) {
  struct ip_iovec *cur = iov;
  while (cur != NULL) {
    int i;
    printfUART("iovec (%p, %i) ", cur, cur->iov_len);
    for (i = 0; i < cur->iov_len; i++) {
      printfUART("%02hhx ", cur->iov_base[i]);
    }
    printfUART("\n");
    cur = cur->iov_next;
  }
}

  
  event void IP.recv(void *iph, void *payload, size_t len, struct ip6_metadata *meta) {
    struct ip6_hdr *hdr = iph;
    struct ip6_packet reply;
    struct ip_iovec v;
    struct icmp6_hdr *req = (struct icmp6_hdr *)payload;

    switch (req->type) {
    case ICMP_TYPE_ECHO_REQUEST:
      req->type = ICMP_TYPE_ECHO_REPLY;
      req->cksum = 0;

      memset(&reply, 0, sizeof(reply));
      memcpy(reply.ip6_hdr.ip6_src.s6_addr, hdr->ip6_dst.s6_addr, 16);
      memcpy(reply.ip6_hdr.ip6_dst.s6_addr, hdr->ip6_src.s6_addr, 16);

      reply.ip6_hdr.ip6_vfc = IPV6_VERSION;
      reply.ip6_hdr.ip6_nxt = IANA_ICMP;
      reply.ip6_data = &v;

      v.iov_next = NULL;
      v.iov_base = payload;
      v.iov_len  = len;

      reply.ip6_hdr.ip6_plen = ntohs(iov_len(&v));

      req->cksum = htons(msg_cksum(&reply.ip6_hdr, reply.ip6_data, IANA_ICMP));
      // iov_print(&v);

      call IP.send(&reply);
      break;

    default:
      signal ICMP_IP.recv[req->type](iph, payload, len, meta);
    }
  }

  command error_t ICMP_IP.send[uint8_t type](struct ip6_packet *pkt) {
    return call IP.send(pkt);
  }

 default event void ICMP_IP.recv[uint8_t nxt_hdr](void *iph, void *payload, size_t len, struct ip6_metadata *meta) {}

}
