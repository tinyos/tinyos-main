
interface IPPacket {
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
  command int findHeader(struct ip_iovec *payload,
                         uint8_t first_type, uint8_t *search_type);
  
  command int findTLV(struct ip_iovec *header, 
                      int ext_offset, 
                      uint8_t type);
  command void delTLV(struct ip_iovec *data, 
                      int ext_offset, 
                      uint8_t type);
  
}
