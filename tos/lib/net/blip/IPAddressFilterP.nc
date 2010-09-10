
module IPAddressFilterP {
  provides {
    interface IPLower as LocalIP;
    interface IPLower as ForwardIP;
  }
  uses {
    interface IPLower as SubIP;
    interface IPAddress;
  }
} implementation {

  event void SubIP.recv(struct ip6_hdr *iph, void *payload, struct ip6_metadata *meta) {
    if (call IPAddress.isLocalAddress(&iph->ip6_dst)) {
      signal LocalIP.recv(iph, payload, meta);
    } else {
      signal ForwardIP.recv(iph, payload, meta);
    }
  }

  command error_t LocalIP.send(struct ieee154_frame_addr *next_hop, struct ip6_packet *msg, void *data) {
    return call SubIP.send(next_hop, msg, data);
  }

  command error_t ForwardIP.send(struct ieee154_frame_addr *next_hop, struct ip6_packet *msg, void *data) {
    return call SubIP.send(next_hop, msg, data);
  }

  event void SubIP.sendDone(struct send_info *si) {
    printfUART("SubIP.sendDone: %p %i %i\n", si->upper_data, si->link_fragments, si->link_transmissions);
  }

 default event void ForwardIP.recv(struct ip6_hdr *iph, void *payload, struct ip6_metadata *meta) {}
}
