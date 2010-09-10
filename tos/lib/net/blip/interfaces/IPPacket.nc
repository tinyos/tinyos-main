
interface IPPacket {
  
  /* Add a section of data to an existing ip6_packet, at offset @offset
     The most primative way of adding data to an ipv6 data packet.

   @offset the offset from the first octet of the IPPv6 header; cannot
   be less then sizeof(struct ip6_hdr)
   @data the buffer to add
   @len the length of the segment to add, or IP6PKT_APPEND to add to the end.
   @return FAIL if there are no more iovec entries availabile in the packet; SUCCESS otherwise.

  */
  command error_t insert(struct ip6_packet *pkt, int offset,
                         uint8_t *data, int len);

  command error_t write(struct ip6_packet *pkt, int offset,
                        uint8_t *data, int len);


  /* Read len bytes from offset into buf.  returns the number of bytes
     actually read. */
  command int read(struct ip6_packet *pkt, int offset, int len, uint8_t *buf);
  /* 
   * @return the length of the packet, including the ipv6 header
   */
  command int length(struct ip6_packet *pkt);

  /* 
   * clear the packet 
   */
  command void clear(struct ip6_packet *pkt);

  /*
   * @type the next header value to look for.  valid choices are in
   * ip.h and can be any valid IANA next-header value.  The special
   * value IP6PKT_TRANSPORT will return the offset of the transport
   * header (ie, the first header which is not an IPv6 extension
   * header).

   * @return the offset of the
   * start of a given header within the packet, or -1 if it was not
   * found.
   */
  command int findHeader(struct ip6_packet *pkt, uint8_t type);


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
  command error_t addHeader(struct ip6_packet *pkt, uint8_t type,
                            uint8_t *data, int len);

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
  command error_t addTLVHeader(struct ip6_packet *pkt, uint8_t type, uint8_t subtype,
                               uint8_t *data, int len);
}
