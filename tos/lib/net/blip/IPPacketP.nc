
#include <lib6lowpan/iovec.h>
#include <lib6lowpan/ip.h>

#define IP6PKT_TRANSPORT 0xff

module IPPacketP {
  provides interface IPPacket;
} implementation {

  /*
   * @type the next header value to look for.  valid choices are in
   * ip.h and can be any valid IANA next-header value.  The special
   * value IP6PKT_TRANSPORT will return the offset of the transport
   * header (ie, the first header which is not an IPv6 extension
   * header).

   * @return the offset of the start of a given header within the
   * packet, or -1 if it was not found.
   */
  command int IPPacket.findHeader(void *payload, size_t len, 
                                  uint8_t first_type, uint8_t search_type) {
    int off = 0;
    uint8_t nxt = first_type;
    struct ip6_ext *ext = payload;

    while ((search_type == IP6PKT_TRANSPORT && 
            (nxt == IPV6_HOP  || nxt == IPV6_ROUTING  || nxt == IPV6_FRAG ||
             nxt == IPV6_DEST || nxt == IPV6_MOBILITY || nxt == IPV6_IPV6)) ||
           search_type != nxt) {
      /* don't want to walk off the end */
      if (off > len - sizeof(struct ip6_ext))
        return -1;

      /* don't want to get caught in a loop */
      if (ext->ip6e_len == 0)
        return -1;

      nxt = ext->ip6e_nxt;
      off += ext->ip6e_len;
    }

    if (nxt == IPV6_NONEXT) 
      return -1;
    else
      return off;
  }
}
