
#include <lib6lowpan/iovec.h>
#include <lib6lowpan/ip.h>
#include <lib6lowpan/lib6lowpan.h>

#include "blip_printf.h"

module IPPacketC {
  provides interface IPPacket;
} implementation {
#define MIN(X,Y) ((X) < (Y) ? (X) : (Y))

  /*
   * @type the next header value to look for.  valid choices are in
   * ip.h and can be any valid IANA next-header value.  The special
   * value IP6PKT_TRANSPORT will return the offset of the transport
   * header (ie, the first header which is not an IPv6 extension
   * header).

   * @return the offset of the start of a given header within the
   * packet, or -1 if it was not found.
   */
  command int IPPacket.findHeader(struct ip_iovec *payload,
                                  uint8_t first_type, uint8_t *search_type) {
    int off = 0;
    uint8_t nxt = first_type;
    struct ip6_ext ext;

    /* ignore extension headers until we find the desired header type
       or reach the transport-layer header. */
    while ((*search_type == IP6PKT_TRANSPORT && 
            (nxt == IPV6_HOP  || nxt == IPV6_ROUTING  || nxt == IPV6_FRAG ||
             nxt == IPV6_DEST || nxt == IPV6_MOBILITY)) || // consider IPV6_IPV6 a transport type
           (*search_type != IP6PKT_TRANSPORT && *search_type != nxt)) {

      if (iov_read(payload, off, sizeof(ext), (void *)&ext) != sizeof(ext))
        return -1;

      nxt = ext.ip6e_nxt;
      off += (ext.ip6e_len + 1) * 8;
    }
    if (*search_type == IP6PKT_TRANSPORT)
      *search_type = nxt;
    if (nxt == IPV6_NONEXT) 
      return -1;
    else
      return off;
  }

  /**
   * Find a TLV-encoded suboption inside of an IPv6 extension header.
   *
   * @header iovec holding the packet data
   * @ext_offset the offset to the first byte of the extension header
   * @type the TLV type value we're looking for
   *
   * @return the offset to the first byte of the matching TLV header, or -1
   */
  command int IPPacket.findTLV(struct ip_iovec *header, int ext_offset, uint8_t type) {
    struct ip6_ext ext;
    struct tlv_hdr tlv;
    int off = ext_offset;

    if (iov_read(header, off, sizeof(ext), (void *)&ext) != sizeof(ext))
      return -1;
    off += sizeof(ext);

    while (off - ext_offset < (ext.ip6e_len + 1) * 8) {
      if (iov_read(header, off, sizeof(tlv), (void *)&tlv) != sizeof(tlv))
        return -1;
      if (tlv.type == type) return off;
      else off += sizeof(tlv) + tlv.len;
    }
    return -1;
  }

  command void IPPacket.delTLV(struct ip_iovec *data, int ext_offset, uint8_t type) {
    uint8_t buf[4];
    struct tlv_hdr tlv;
    // find the TLV option inside the header
    ext_offset = call IPPacket.findTLV(data, ext_offset, type); 
    if (ext_offset < 0)
      return;

    if (iov_read(data, ext_offset, sizeof(tlv), (void *)&tlv) != sizeof(tlv))
      return;
    
    buf[0] = IPV6_TLV_PADN;
    // change the search TLV to a PadN option
    iov_update(data, ext_offset + offsetof(struct tlv_hdr, type), 1, &buf[0]);
    memclr(buf, sizeof(buf));
    ext_offset += sizeof(struct tlv_hdr);

#if 0
    // RFC2460 tells us to PadN options have to be zero-filled
    //   you can do that if you want, but I'm leaving this disabled
    //   because it's useful for debugging to see what the RPL options
    //   were -- SDH 

    // and overwrite the contents with zeroes
    while (tlv.len > 0) {
      int write_amt = MIN(tlv.len, sizeof(buf));
      iov_update(data, ext_offset, write_amt, buf);
      ext_offset += write_amt;
      tlv.len -= write_amt;
    }
#endif
  }
}
