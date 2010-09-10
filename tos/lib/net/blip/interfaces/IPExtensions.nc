
interface IPExtensions {

  command struct tlv_hdr *findTlv(struct ip6_ext *ext, uint8_t tlv);

  event void handleExtensions(uint8_t label,
                              struct ip6_hdr *iph,
                              struct ip6_ext *hop,
                              struct ip6_ext *dst,
                              struct ip6_route *route,
                              uint8_t nxt_hdr);


  /*
   * will be called once for each fragment when sending or forwarding
   */
  event void reportTransmission(uint8_t label, send_policy_t *send);

}
