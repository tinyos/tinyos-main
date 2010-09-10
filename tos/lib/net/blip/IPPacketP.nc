
#include <iovec.h>

module IPPacketP {
  provides interface IPPacket;
} implementation {

 /* Add a section of data to an existing ip6_packet, at offset @offset
     The most primative way of adding data to an ipv6 data packet.

   @offset the offset from the first octet of the IPPv6 header; cannot
   be less then sizeof(struct ip6_hdr)
   @data the buffer to add
   @len the length of the segment to add, or IP6PKT_APPEND to add to the end.
   @return FAIL if there are no more iovec entries availabile in the packet; SUCCESS otherwise.

  */
  command error_t IPPacket.insert(struct ip6_packet *pkt, int offset,
                         uint8_t *data, int len);

  command error_t IPPacket.write(struct ip6_packet *pkt, int offset,
                        uint8_t *data, int len);


  /* Read len bytes from offset into buf.  returns the number of bytes
     actually read. */
  command int IPPacket.read(struct ip6_packet *pkt, int offset, int len, uint8_t *buf) {
    if (offset < sizeof(struct ip6_hdr)) {
      int here = min(len, sizeof(struct ip6_hdr) - offset);
      memcpy(buf, (uint8_t *)&pkt->ip6_hdr, here);
      buf += here;
      offset += here;
      len -= here;
    }
    return iov_read(pkt->ip6_data, offset, len, buf);
  }
  /* 
   * @return the length of the packet, including the ipv6 header
   */
  command int IPPacket.length(struct ip6_packet *pkt) {
    return sizeof(struct ip6_hdr) + iov_len(pkg->ip6_data);
  }

  /* 
   * clear the packet 
   */
  command void IPPacket.clear(struct ip6_packet *pkt) {
    pkt->_ip6_curvec = 0;
    memset(&pkt->ip6_hdr, 0, sizeof(struct ip6_hdr));
  }

  /*
   * @type the next header value to look for.  valid choices are in
   * ip.h and can be any valid IANA next-header value.  The special
   * value IP6PKT_TRANSPORT will return the offset of the transport
   * header (ie, the first header which is not an IPv6 extension
   * header).

   * @return the offset of the start of a given header within the
   * packet, or -1 if it was not found.
   */
  command int IPPacket.findHeader(struct ip6_packet *pkt, uint8_t type) {
    int off = 0;
    uint8_t nxt = iph->ip6_nxt;
    struct ip6_ext ext;

    if (iov_read(pkt->ip6_data, off, sizeof(struct ip6_ext), (uint8_t *)&ext) != 
          sizeof(struct ip6_ext))
      return -1;

    while ((type == IP6PKT_TRANSPORT && 
            (nxt == IPV6_HOP  || nxt == IPV6_ROUTING  || nxt == IPV6_FRAG ||
             nxt == IPV6_DEST || nxt == IPV6_MOBILITY || nxt == IPV6_IPV6)) ||
           type != nxt) {
      nxt = ext.ip6e_nxt;
      off += ext.ip6e_len;

      if (iov_read(pkt->ip6_data, off, sizeof(struct ip6_ext), (uint8_t *)&ext) != 
            sizeof(struct ip6_ext))
        return -1;
    }

    if (nxt == IPV6_NONEXT) 
      return -1;
    else
      return off;
  }


  /* 
   * Add a header to the message. 
   *
   * @type the type value of the header.  If it is a IPv6 extension
   * header, the data will be inserted at the appropriate position.
   * Otherwise, it will be added as a transport header.
   * @data, @len the header to add
   * @return FAIL if type is an extension header and there is already
   * a header of that type, or if type is a transport header and there
   * is an existing transport header.
   */
  command error_t IPPacket.addHeader(struct ip6_packet *pkt, uint8_t type,
                                     uint8_t *data, int len) {
    if (call IPPacket.findHeader(pkt, type) > 0) {
      return FAIL;
    }
  }

  /* 
   * Add a TLV-encoded subheader to a message.
   * 
   * @type the outside container header type; normally either
   * hop-by-hop or destination options, although can be anything
   * @subtype the "type" field of the TLV subheader
   * @data pointer to subheader buffer, including two-octet standard
   * TLV header.  The fields of this header will be overwritten with
   * the subtype and len parameters.
   */
  command error_t IPPacket.addTLVHeader(struct ip6_packet *pkt, uint8_t type, uint8_t subtype,
                               uint8_t *data, int len);

}
