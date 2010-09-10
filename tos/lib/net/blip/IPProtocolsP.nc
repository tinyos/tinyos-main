
module IPProtocolsP {
  provides {
    interface IP[uint8_t nxt_hdr];
  }
  uses {
    interface IPAddress;
    interface IPLower as SubIP;
  }
} implementation {

  event void SubIP.recv(struct ip6_hdr *iph, void *payload, struct ip6_metadata *meta) {
    struct ip6_ext *cur = (struct ip6_ext *)payload;
    uint8_t nxt = iph->ip6_nxt;

    while (nxt == IPV6_HOP  || nxt == IPV6_ROUTING  || nxt == IPV6_FRAG ||
           nxt == IPV6_DEST || nxt == IPV6_MOBILITY || nxt == IPV6_IPV6) {
      nxt = cur->ip6e_nxt;
      cur = cur + cur->ip6e_len;
    }

    signal IP.recv[nxt](iph,
                        cur,
                        ntohs(iph->ip6_plen) - ((void *)cur - payload),
                        meta);
  }
                        

  command error_t IP.send[uint8_t nxt_hdr](struct ip6_packet *msg) {
    struct ieee154_frame_addr fr_addr;

    msg->ip6_hdr.ip6_hlim = 100;

    if (call IPAddress.resolveAddress(&msg->ip6_hdr.ip6_src, &fr_addr.ieee_src) != SUCCESS) {
      printfUART("resolve failed: src\n");
    }
    if (call IPAddress.resolveAddress(&msg->ip6_hdr.ip6_dst, &fr_addr.ieee_dst) != SUCCESS) {
      printfUART("resolve failed: src\n");
    }
    fr_addr.ieee_dstpan = TOS_AM_GROUP;

    return call SubIP.send(&fr_addr, msg, NULL);
  }

  event void SubIP.sendDone(struct send_info *si) {}

 default event void IP.recv[uint8_t nxt_hdr](void *iph, void *payload, size_t len, struct ip6_metadata *meta) {}
}
