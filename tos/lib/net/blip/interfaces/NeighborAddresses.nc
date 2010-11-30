
interface NeighborAddresses {

  /* 
   * Look up the IP addresses in the IP header and fill in the
   * appropriate link-layer addresses in the packet header structure.
   */
  command error_t lookupAddresses(struct ip6_addr *hdr, struct ieee154_frame_addr *addrs);

}
