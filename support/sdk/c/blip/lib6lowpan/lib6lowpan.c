/* Implementation of RFC6282 */
/* @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu> */
/* @author Brad Campbell <bradjc@umich.edu> */

/* Each function in this file should have an associated set of test
 * cases in tests/
 *
 * The library is built up from small functions which take care of one
 * element of compressor or decompression.  This way, we can unit-test
 * all the little pieces separately and then have one big function
 * which merely applies them in the right order.  In general, HC
 * allows you to do this pretty well -- the only real state you need
 * to hang onto is the dispatch block at the beginning of the
 * encoding.
*/

#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#ifdef UNIT_TESTING
#include <stdio.h>
#else
// #define printf(fmt, args ...) ;
#endif

#include "lib6lowpan-includes.h"
#include "lib6lowpan.h"
#include "ip.h"
#include "Ieee154.h"
#include "ieee154_header.h"
#include "internal.h"

/* UTILITY MACROS AND FUNCTIONS */

/* test if the first 64-bits are fe80::/64 */
#define IS_LINKLOCAL(ADDR) \
  ((ADDR)->s6_addr16[0] == htons(0xfe80) && \
   (ADDR)->s6_addr16[1] == 0 && \
   (ADDR)->s6_addr16[2] == 0 && \
   (ADDR)->s6_addr16[3] == 0)

/* test if the address is all zeroes */
#define IS_UNSPECIFIED(ADDR) \
  ((ADDR)->s6_addr16[0] == 0 && \
   (ADDR)->s6_addr16[1] == 0 && \
   (ADDR)->s6_addr16[2] == 0 && \
   (ADDR)->s6_addr16[3] == 0 && \
   (ADDR)->s6_addr16[4] == 0 && \
   (ADDR)->s6_addr16[5] == 0 && \
   (ADDR)->s6_addr16[6] == 0 && \
   (ADDR)->s6_addr16[7] == 0)

#if ! defined(HAVE_LOWPAN_EXTERN_MATCH_CONTEXT)
int lowpan_extern_read_context(struct in6_addr *addr, int context) {
  return -1;
}

int lowpan_extern_match_context(struct in6_addr *addr, UNUSED uint8_t *ctx_id) {
  return 0;
}

#endif

int iid_eui_cmp(uint8_t *iid, uint8_t *eui) {
  return (iid[0] == (eui[7] ^ 0x2) &&
          iid[1] == eui[6] &&
          iid[2] == eui[5] &&
          iid[3] == eui[4] &&
          iid[4] == eui[3] &&
          iid[5] == eui[2] &&
          iid[6] == eui[1] &&
          iid[7] == eui[0]);
}

/* @return 0 if all bits in the range [start,end) are zero */
/*    -1 otherwise */
int bit_range_zero_p(uint8_t *buf, int start, int end) {
  int start_byte = start / 8;
  int end_byte   = end / 8;
  int i;
  uint8_t start_mask = 0xff << (8 - (start % 8));
  uint8_t end_mask   = 0xff << (8 - (end % 8));
  // printf("start: %i end: %i, (%i, %i)\n", start, end, start_byte, end_byte);
  // printf("start mask: 0x%x end mask: 0x%x\n", start_mask, end_mask);

  if ((buf[start_byte] & start_mask) != 0) {
    return -1;
  }
  if ((buf[end_byte] & end_mask) != 0) {
    return -1;
  }
  for (i = start_byte; i < end_byte; i++) {
    if (buf[i] != 0) return -1;
  }
  return 0;
}

/* HEADER PACKING  */
/*   functions for creating a compressed representation of an IPv6 header */

/* Packs the Traffic Class and Flow Label fields as described in the internet
 * draft.
 *
 * @buf      the buffer to write any anyline fields to
 * @hdr      the IPv6 header being compressed; this function only examines the
 *           first four octets
 * @dispatch the octet corresponding to the first octet of the IPHC dispatch
 *           value modified to reflect the packing of the fields
 */
inline uint8_t *pack_tcfl(uint8_t *buf,
                          struct ip6_hdr *hdr,
                          uint8_t *dispatch) {
  uint32_t flow = (ntohl(hdr->ip6_flow) & 0x000fffff);
  uint8_t  tc   = (ntohl(hdr->ip6_flow) >> 20) & 0xff;
  if (flow == 0 && tc == 0) {
    // lucky us
    *dispatch |= LOWPAN_IPHC_TF_NONE;
  } else if (flow == 0) {
    *dispatch |= LOWPAN_IPHC_TF_ECN_DSCP;
    *buf  = (tc >> 2) & 0xff;
    *buf |= (tc << 6) & 0xff;
    buf++;
  } else if ((tc & 0x3) == tc) {
    *dispatch |= LOWPAN_IPHC_TF_ECN_FL;
    *buf        = (tc << 6) & 0xff;
    *buf       |= (flow >> 16) & 0x0f;
    *(buf + 1)  = (flow >> 8)  & 0xff;
    *(buf + 2)  = (flow)       & 0xff;
    buf += 3;
  } else {
    *dispatch |= LOWPAN_IPHC_TF_ECN_DSCP_FL;
    *buf  = (tc >> 2) & 0xff;
    *buf |= (tc << 6) & 0xff;

    *(buf + 1)  = (flow >> 16) & 0x0f;
    *(buf + 2)  = (flow >> 8)  & 0xff;
    *(buf + 3)  = (flow)       & 0xff;
    buf += 4;
  }
  return buf;
}

inline uint8_t *pack_nh(uint8_t *buf, struct ip6_hdr *hdr, uint8_t *dispatch) {
  uint8_t nxt = hdr->ip6_nxt;
  if (nxt == IPV6_HOP  || nxt == IPV6_ROUTING  || nxt == IPV6_FRAG ||
      nxt == IPV6_DEST || nxt == IPV6_MOBILITY || nxt == IPV6_IPV6 ||
      nxt == IANA_UDP) {
    *dispatch |= LOWPAN_IPHC_NH_MASK;
  } else {
    *buf++ = hdr->ip6_nxt;
  }
  return buf;
}

inline uint8_t *pack_hlim(uint8_t *buf,
                          struct ip6_hdr *hdr,
                          uint8_t *dispatch) {
  if (hdr->ip6_hlim == 1) {
    *dispatch |= LOWPAN_IPHC_HLIM_1;
  } else if (hdr->ip6_hlim == 64) {
    *dispatch |= LOWPAN_IPHC_HLIM_64;
  } else if (hdr->ip6_hlim == 255) {
    *dispatch |= LOWPAN_IPHC_HLIM_255;
  } else {
    *dispatch |= LOWPAN_IPHC_HLIM_NONE;
    *buf++ = hdr->ip6_hlim;
  }
  return buf;
}

/* Packs all non-multicast addresses.
 *
 * @buf               output buffer
 * @addr              the ipv6 address to be compressed
 * @context_match_len if a context matches, how long the match is. must be
 *                    multiple of 8
 * @l2addr            the link-layer address correspoinding to the address
 *                    (source or destination)
 * @pan               the destination pan ID
 * @flags             return argument; which address mode was selected
 */
uint8_t *pack_address(uint8_t *buf,
                      struct in6_addr *addr,
                      int context_match_len,
                      ieee154_addr_t *l2addr,
                      ieee154_panid_t pan,
                      uint8_t *flags) {
  *flags = 0;
  if (IS_LINKLOCAL(addr)) {
    /* then we use stateless compression */
    /*     no bits to set, just pack the IID */
    if (addr->s6_addr16[4] == 0 &&
        addr->s6_addr16[5] == 0 &&
        addr->s6_addr16[6] == 0) {
      // then we use 16-bit mode.  This isn't going to be popular...
      *flags |= LOWPAN_IPHC_AM_16;
      memcpy(buf, &addr->s6_addr[14], 2);
      return buf += 2;
    } else if (/* maybe it's a 16-bit address with the IID derived from the
                  802.15.4 address(RFC 6282 Section 3.2.2) */
                (addr->s6_addr16[5] == htons(0x00ff) &&
                addr->s6_addr16[6] == htons(0xfe00) &&
                (((l2addr->ieee_mode == IEEE154_ADDR_SHORT) &&
                  addr->s6_addr16[7] == htons(letohs(l2addr->i_saddr))))) ||
               /* no?  Maybe it's just a straight-up 64-bit EUI64 */
                 ((l2addr->ieee_mode == IEEE154_ADDR_EXT) &&
                  (iid_eui_cmp(&addr->s6_addr[8], l2addr->i_laddr.data)))) {
      /* in either case we can elide the addressing from the packet. */
      *flags |= LOWPAN_IPHC_AM_0;
      return buf;
    } else {
      *flags |= LOWPAN_IPHC_AM_64;
      memcpy(buf, &addr->s6_addr[8], 8);
      return buf + 8;
    }
  } else if (context_match_len > 0) {
    int extra = 0;
    // then we're using the context
    *flags |= LOWPAN_IPHC_AC_CONTEXT;
    if (context_match_len == 128) {
      *flags |= LOWPAN_IPHC_AM_0;
    } else if (bit_range_zero_p(&addr->s6_addr[0],
                                context_match_len, 112) == 0) {
      *flags |= LOWPAN_IPHC_AM_16;
      memcpy(buf, &addr->s6_addr[14], 2);
      extra = 2;
    } else if (bit_range_zero_p(&addr->s6_addr[0],
                                context_match_len, 64) == 0) {
      // The upper 64 bits of this address either match the global prefix or
      // are zero. Either of which the receiving node can figure out with
      // its own prefix.
      if ((l2addr->ieee_mode == IEEE154_ADDR_EXT) &&
          (iid_eui_cmp(&addr->s6_addr[8], l2addr->i_laddr.data))) {
        // The lower 64 bits of the address match the EUI64 from the 802.15.4
        // header. Therefore we can elide the entire address.
        *flags |= LOWPAN_IPHC_AM_0;
      } else {
        // Need to include the lower 64 bits in the packet.
        *flags |= LOWPAN_IPHC_AM_64;
        memcpy(buf, &addr->s6_addr[8], 8);
        extra = 8;
      }
    } else {
      *flags |= LOWPAN_IPHC_AM_128;
      *flags &= ~LOWPAN_IPHC_AC_CONTEXT;
      memcpy(buf, &addr->s6_addr[0], 16);
      extra = 16;
    }
    return buf + extra;
  } else if (IS_UNSPECIFIED(addr)) {
    /* this case doesn't involve any compression */
    *flags |= LOWPAN_IPHC_AC_CONTEXT | LOWPAN_IPHC_AM_128;
    return buf;
  } else {
    /* otherwise we have to send the whole thing. */
    *flags |= LOWPAN_IPHC_AM_128;
    memcpy(buf, addr->s6_addr, 16);
    return buf + 16;
  }
}

/* Packs a multicast address into the smallest address possible. */
/*  does not currently implement stateful multicast address compression */
/*  also does not check to make sure it is a multicast address */
uint8_t *pack_multicast(uint8_t *buf, struct in6_addr *addr, uint8_t *flags) {
  /* no need to set AC since it's zero */
  *flags = 0;
  if ((addr->s6_addr16[0] == htons(0xff02)) &&
      (bit_range_zero_p(addr->s6_addr, 16, 120) == 0)) {
    *flags |= LOWPAN_IPHC_AM_M_8;
    *buf = addr->s6_addr[15];
    return buf + 1;
  } else if (bit_range_zero_p(addr->s6_addr, 16, 104) == 0) {
    *flags |= LOWPAN_IPHC_AM_M_32;
    *buf = addr->s6_addr[1];
    memcpy(buf + 1, &addr->s6_addr[13], 3);
    return buf + 4;
  } else if (bit_range_zero_p(addr->s6_addr, 16, 88) == 0) {
    *flags |= LOWPAN_IPHC_AM_M_48;
    *buf = addr->s6_addr[1];
    memcpy(buf + 1, &addr->s6_addr[11], 5);
    return buf + 6;
  } else {
    *flags += LOWPAN_IPHC_AM_M_128;
    memcpy(buf, addr->s6_addr, 16);
    return buf + 16;
  }
}

/* Compress the udp header.
 * Never pack the ports, currently.
 *
 * Returns the amount read out of the packet.
 */
int pack_nhc_udp(uint8_t **dest,
                 size_t *dlen,
                 struct ip6_packet *packet,
                 int offset) {
  struct udp_hdr udp;

  if (*dlen < 7) return -1;

  if (iov_read(packet->ip6_data, offset, sizeof(struct udp_hdr), (void*)&udp) !=
      sizeof(struct udp_hdr)) {
    return -1;
  }

  (*dest)[0] = LOWPAN_NHC_UDP_PATTERN | LOWPAN_NHC_UDP_PORT_FULL;
  memcpy(*dest + 1, &udp.srcport, 4);
  memcpy(*dest + 5, &udp.chksum, 2);
  *dest += 7; *dlen -= 7;

  return sizeof(struct udp_hdr);
}


/* @type the next header value of the header we are inspecting
 * @pkt an iovec storing the packet being compressed
 * @offset the offset to the start of the extension header we are interested in
 *
 * @return the length of the header, in octets, eliding any trailing
 * padding options. on error, 0, since the shortest possible extension
 * header is of length 2 and that would be in the case where it
 * contains only padding. */
uint8_t __ipnh_real_length(uint8_t type, struct ip_iovec *pkt, int offset) {
  int start_offset = offset, end_offset = offset + 2;
  struct ip6_ext ext;
  struct tlv_hdr tlv;
  if (iov_read(pkt, offset, 2, (void *)&ext) != 2)
    return 0;

  /* If it's neither of these two types, the length of valid data is contained
   * in the header. Otherwise, we need to find where real data ends and
   * padding begins. */
  if (type != IPV6_HOP && type != IPV6_DEST)
    return (ext.ip6e_len + 1) * 8;

  offset += 2;
  for (;;) {
    if (offset >= ((ext.ip6e_len + 1) * 8) + start_offset) break;
    if (iov_read(pkt, offset, 2, (void *)&tlv) != 2)
      return -1;

    if (tlv.type == IPV6_TLV_PAD1) {
      offset += 1;
    } else {
      offset += 2 + tlv.len;
      if (tlv.type != IPV6_TLV_PADN) {
        end_offset = offset;
      }
    }
  }

  /* the length of the TLVs didn't match the length in the enclosing header */
  if (offset - start_offset != (ext.ip6e_len + 1) * 8) {
    return 0;
  }

  /* length up to the first padding option encountered which was not
     followed by a non-padding option. */
  return end_offset - start_offset;
}

int pack_nhc_ipv6_ext(uint8_t **dest,
                      size_t *dlen,
                      uint8_t *type,
                      struct ip6_packet *packet,
                      int offset) {
  struct ip6_ext ext;
  uint8_t real_len;

  /* read the ipv6 extension header out for processing */
  if (iov_read(packet->ip6_data, offset, 2, (void *)&ext) != 2) {
    return -1;
  }

  if (ext.ip6e_len > *dlen) return -1;

  (*dest)[0] = LOWPAN_NHC_IPV6_PATTERN;
  switch (*type) {
  case IPV6_HOP:      (*dest)[0] |= LOWPAN_NHC_EID_HOP; break;
  case IPV6_ROUTING:  (*dest)[0] |= LOWPAN_NHC_EID_ROUTING; break;
  case IPV6_FRAG:     (*dest)[0] |= LOWPAN_NHC_EID_FRAG; break;
  case IPV6_DEST:     (*dest)[0] |= LOWPAN_NHC_EID_DEST; break;
  case IPV6_MOBILITY: (*dest)[0] |= LOWPAN_NHC_EID_MOBILE; break;
  default: return -1;
  }

  real_len = __ipnh_real_length(*type, packet->ip6_data, offset);
  if (real_len == 0) return -1;

  /* store the next header type */
  /*  if it's compressable, we will compress it */
  *type = ext.ip6e_nxt;
  if (ext.ip6e_nxt == IPV6_HOP      || ext.ip6e_nxt == IPV6_ROUTING  ||
      ext.ip6e_nxt == IPV6_FRAG     || ext.ip6e_nxt == IPV6_DEST     ||
      ext.ip6e_nxt == IPV6_MOBILITY || ext.ip6e_nxt == IPV6_IPV6     ||
      ext.ip6e_nxt == IANA_UDP) {
    (*dest)[0] |= LOWPAN_NHC_NH;
  } else {
    /* include the next header value if it's not compressible */
    *dest += 1; *dlen -= 1;
    (*dest)[0] = ext.ip6e_nxt;
  }
  *dest += 1; *dlen -= 1;

  /* Insert the length (in bytes) of the header */
  /* The length field "indicates the number of octets that pertain to the
   * (compressed) extension header following the Length field" so we subtract
   * 2 for the next header and length bytes. */
  (*dest)[0] = real_len - 2;
  *dest += 1; *dlen -= 1;

  /* Copy the payload */
  if (iov_read(packet->ip6_data, offset+2, real_len-2, *dest) != real_len - 2)
    return -1;
  *dest += real_len - 2; *dlen -= real_len - 2;

  /* Continue processing at the next header; which will ignore any padding
     options */
  return (ext.ip6e_len + 1) * 8;
}

int pack_nhc_chain(uint8_t **dest, size_t *dlen, struct ip6_packet *packet) {
  uint8_t nxt = packet->ip6_hdr.ip6_nxt;
  int offset = 0, rv;
  /* @return offset is the offset into the unpacked ipv6 datagram */
  /* dest is updated to show how far we have gotten in the packed data */

  while (nxt == IPV6_HOP  || nxt == IPV6_ROUTING  || nxt == IPV6_FRAG ||
         nxt == IPV6_DEST || nxt == IPV6_MOBILITY || nxt == IPV6_IPV6) {
    rv = pack_nhc_ipv6_ext(dest, dlen, &nxt, packet, offset);
    if (rv < 0) return -1;

    /* Increment the offset past the header we just compressed. */
    offset += rv;
  }

  if (nxt == IANA_UDP) {
    rv = pack_nhc_udp(dest, dlen, packet, offset);
    if (rv < 0) return -1;

    offset += rv;
  }
  return offset;
}

uint8_t * lowpan_pack_headers(struct ip6_packet *packet,
                        struct ieee154_frame_addr *frame,
                        uint8_t *buf, size_t cnt) {
  uint8_t *dispatch, temp_dispatch, ctx_match_length;

  if ((packet->ip6_hdr.ip6_vfc & IPV6_VERSION_MASK) != IPV6_VERSION) {
    return NULL;
  }

  /* Packing strategy: */
  /*   1. we never create 6lowpan broadcast or mesh frames */
  /*   2. first, pack the IP headers and any other compressible header into the
          frame */
  /*   3. if the data will fit into the frame, copy it in too */
  /*   4. otherwise, do a memmove(3) and insert a fragmentation header */
  /* We'll then test the whole thing as a unit. */
  /* There is no support for using more then a single context, and no
     support for stateful packing of multicast addresses.

     These things are only supported in decompression, for compatibility.
   */
  dispatch = buf;
  *dispatch = LOWPAN_DISPATCH_BYTE_VAL;
  *(dispatch+1) = 0;
  buf += 2;

  buf = pack_tcfl(buf, &packet->ip6_hdr, dispatch);
  buf = pack_nh(buf, &packet->ip6_hdr, dispatch);
  buf = pack_hlim(buf, &packet->ip6_hdr, dispatch);

  /* back the source and destination addresses */
  ctx_match_length = lowpan_extern_match_context(&packet->ip6_hdr.ip6_src,
                                                 &temp_dispatch);
  temp_dispatch = 0;
  buf = pack_address(buf, &packet->ip6_hdr.ip6_src, ctx_match_length,
                     &frame->ieee_src, frame->ieee_dstpan, &temp_dispatch);
  *(dispatch+1) |= temp_dispatch << LOWPAN_IPHC_SAM_SHIFT;

  if (packet->ip6_hdr.ip6_dst.s6_addr[0] != 0xff) {
    /* not multicast */
    ctx_match_length = lowpan_extern_match_context(&packet->ip6_hdr.ip6_dst,
                                                   &temp_dispatch);
    temp_dispatch = 0;
    buf = pack_address(buf, &packet->ip6_hdr.ip6_dst, ctx_match_length,
                       &frame->ieee_dst, frame->ieee_dstpan, &temp_dispatch);
    *(dispatch+1) |= temp_dispatch << LOWPAN_IPHC_DAM_SHIFT;
  } else {
    /* multicast */
    buf = pack_multicast(buf, &packet->ip6_hdr.ip6_dst, &temp_dispatch);
    *(dispatch + 1) |= (temp_dispatch << LOWPAN_IPHC_DAM_SHIFT) |
                       LOWPAN_IPHC_AM_M;
  }

  return buf;
}

/* Extend the dispatch block if the context extension is present.
 * Returns 0 on success and -1 if the buffer is too short.
 */
int unpack_context(uint8_t dispatch,
                   int *contexts,
                   uint8_t **buf,
                   size_t *len) {
  if ((dispatch & LOWPAN_IPHC_CID_MASK) == LOWPAN_IPHC_CID_PRESENT) {
    if (*len < 1) return -1;
    contexts[0] = (**buf >> 4) & 0xf;
    contexts[1] = (**buf) & 0xf;
    *buf += 1; *len -= 1;
  }
  return 0;
}

/* Unpack tcfl. Updates the buf pointer and length with the buffer it uses
 * when unpacking.
 * Returns 0 on success and -1 if there isn't enough length left in the buffer
 * to unpack.
 */
int unpack_tcfl(struct ip6_hdr *hdr,
                uint8_t dispatch,
                uint8_t **buf,
                size_t *len) {
  uint8_t fl[3] = {0,0,0};
  uint8_t tc = 0;

  switch (dispatch & LOWPAN_IPHC_TF_MASK) {
  case LOWPAN_IPHC_TF_ECN_DSCP:
    if (*len < 1) return -1;
    tc  = ((*buf)[0] >> 6) & 0xff;
    tc |= ((*buf)[0] << 2) & 0xff;
    *buf += 1; *len -= 1;
    break;
  case LOWPAN_IPHC_TF_ECN_FL:
    if (*len < 3) return -1;
    tc = ((*buf)[0] >> 6) & 0xff;
    fl[2] = (*buf)[0] & 0x0f;
    fl[1] = (*buf)[1];
    fl[0] = (*buf)[2];
    *buf += 3; *len -= 3;
    break;
  case LOWPAN_IPHC_TF_ECN_DSCP_FL:
    if (*len < 4) return -1;
    tc  = ((*buf)[0] >> 6) & 0xff;
    tc |= ((*buf)[0] << 2) & 0xff;
    fl[2] = (*buf)[1] & 0x0f;
    fl[1] = (*buf)[2];
    fl[0] = (*buf)[3];
    *buf += 4; *len -= 4;
    break;
  }

  hdr->ip6_flow = htonl(((uint32_t)0x6 << 28) |
                        ((uint32_t)tc << 20) |
                        ((uint32_t)fl[2] << 16) |
                        ((uint32_t)fl[1] << 8) | fl[0]);
  return 0;
}

/* Unpack the next header byte.
 * Returns 0 on success and -1 if the buffer is too short.
 */
int unpack_nh(struct ip6_hdr *hdr,
              uint8_t dispatch,
              uint8_t **buf,
              size_t *len) {
  if ((dispatch & LOWPAN_IPHC_NH_MASK) == LOWPAN_IPHC_NH_INLINE) {
    if (*len < 1) return -1;
    hdr->ip6_nxt = **buf;
    *buf += 1; *len -= 1;
  }
  return 0;
}

/* Unpack the hop limit.
 * Returns 0 on success and -1 if the buffer is too short.
 */
int unpack_hlim(struct ip6_hdr *hdr,
                uint8_t dispatch,
                uint8_t **buf,
                size_t *len) {
  switch (dispatch & LOWPAN_IPHC_HLIM_MASK) {
  case LOWPAN_IPHC_HLIM_1:
    hdr->ip6_hlim = 1;
    break;
  case LOWPAN_IPHC_HLIM_64:
    hdr->ip6_hlim = 64;
    break;
  case LOWPAN_IPHC_HLIM_255:
    hdr->ip6_hlim = 255;
    break;
  default:
    if (*len < 1) return -1;
    hdr->ip6_hlim = (*buf)[0];
    *buf += 1; *len -= 1;
  }
  return 0;
}

/* Unpacks a compressed address from a buffer.
 * @addr     Output address struct
 * @dispatch Shifted bits corresponding to the dispatch byte. The raw dispatch
 *           byte will have to shift depending on if this is the src or dest
 *           address.
 * @context  Length (in bits) of the context to get the address from in stateful
 *           mode.
 * @buf      Pointer to a buffer to parse the address from
 * @len      Pointer to the number of valid bytes in the buffer
 * @frame    802.15.4 header
 * @pan      PAN id of the network
 * @stateful Return bool that is set to TRUE when stateful address uncompression
 *           with context was used. It will not be changed if stateless is used.
 *           Knowing this is useful in the case where a checksum may need
 *           to be recalculated.
 *
 * Return:   0 on success, -1 if the buffer is too short and -2 on other
 *           failure. Updates the buf pointer and remaining length.
 */
int unpack_address(struct in6_addr *addr,
                   uint8_t dispatch,
                   int context,
                   uint8_t **buf,
                   size_t *len,
                   ieee154_addr_t *frame,
                   ieee154_panid_t pan,
                   uint8_t *stateful) {
  memset(addr, 0, 16);
  if(!((dispatch & LOWPAN_IPHC_AC_CONTEXT))) {
    /* stateless compression */
    switch (dispatch & LOWPAN_IPHC_AM_MASK) {
    case LOWPAN_IPHC_AM_128:
      if (*len < 16) return -1;
      memcpy(addr, *buf, 16);
      *buf += 16; *len -= 16;
      return 0;
    case LOWPAN_IPHC_AM_64:
      if (*len < 8) return -1;
      addr->s6_addr16[0] = htons(0xfe80);
      memcpy(&addr->s6_addr[8], *buf, 8);
      *buf += 8; *len -= 8;
      return 0;
    case LOWPAN_IPHC_AM_16:
      if (*len < 2) return -1;
      addr->s6_addr16[0] = htons(0xfe80);
      memcpy(&addr->s6_addr[14], *buf, 2);
      *buf += 2; *len -= 2;
      return 0;
    default:
      addr->s6_addr16[0] = htons(0xfe80);
      if (frame->ieee_mode == IEEE154_ADDR_EXT) {
        int i;
        for (i = 0; i < 8; i++)
          addr->s6_addr[i+8] = frame->i_laddr.data[7-i];
        addr->s6_addr[8] ^= 0x2;
      } else {
        addr->s6_addr[11] = 0xff;
        addr->s6_addr[12] = 0xfe;
        addr->s6_addr16[7] = leton16(frame->i_saddr);
      }
      return 0;
    }
  } else {
    /* context-based compression */
    if ((dispatch & LOWPAN_IPHC_AM_MASK) == LOWPAN_IPHC_AM_128) {
      // unspecified address ::
      return 0;
    } else {
      int ctxlen = lowpan_extern_read_context(addr, context);
      *stateful = 1;
      switch (dispatch & LOWPAN_IPHC_AM_MASK) {
      case LOWPAN_IPHC_AM_64:
        if (*len < 8) return -1;
        memcpy(&addr->s6_addr[8], *buf, 8);
        *buf += 8; *len -= 8;
        return 0;
      case LOWPAN_IPHC_AM_16:
        if (*len < 2) return -1;
        memcpy(&addr->s6_addr[14], *buf, 2);
        *buf += 2; *len -= 2;
        return 0;
      case LOWPAN_IPHC_AM_0:
        // not clear how to use this:
        //  "and 'possibly' link-layer addresses"
        if (ctxlen <= 64 && frame->ieee_mode == IEEE154_ADDR_EXT) {
            int i;
            for (i = 0; i < 8; i++)
              addr->s6_addr[i+8] = frame->i_laddr.data[7-i];
            addr->s6_addr[8] ^= 0x2;
        } else if (ctxlen <= 112) {
          memset(&addr->s6_addr[8], 0, 8);
          addr->s6_addr16[7] = leton16(frame->i_saddr);
        }
        return 0;
      }
    }
  }
  return -2;
}

/* Unpack a multicast compressed address.
 *
 * Returns 0 on success.
 */
int unpack_multicast(struct in6_addr *addr,
                     uint8_t dispatch,
                     int context,
                     uint8_t **buf,
                     size_t *len) {
  memset(addr->s6_addr, 0, 16);

  if (!(dispatch & LOWPAN_IPHC_AC_CONTEXT)) {
    int amount;
    switch (dispatch & LOWPAN_IPHC_AM_MASK) {
    case LOWPAN_IPHC_AM_M_128:
      if (*len < 16) return -1;
      memcpy(addr->s6_addr, *buf, 16);
      *buf += 16; *len -= 16;
      return 0;
    case LOWPAN_IPHC_AM_M_48:
      amount = 5;
      goto copy;
    case LOWPAN_IPHC_AM_M_32:
      amount = 3;
    copy:
      if (*len < amount + 1) return -1;
      addr->s6_addr[0] = 0xff;
      addr->s6_addr[1] = *buf[0];
      memcpy(&addr->s6_addr[16-amount], (*buf) + 1, amount);
      *buf += amount + 1; *len -= amount + 1;
      return 0;
    case LOWPAN_IPHC_AM_M_8:
      if (*len < 1) return -1;
      addr->s6_addr16[0] = htons(0xff02);
      addr->s6_addr[15]  = (*buf)[0];
      *buf += 1; *len -= 1;
      return 0;
    }
  } else {
    // stateful multicast compression
    // all you need to do is read in the context here...
  }
  return -2;
}

/* Unpack a compressed UDP header.
 *
 * Returns 0 on success, -1 if the source buffer is too short, -2 if the dest
 * buffer is too short.
 */
int unpack_nhc_udp(struct lowpan_reconstruct *recon,
                   uint8_t **dest,
                   size_t *dlen,
                   uint8_t *nxt_hdr,
                   uint8_t dispatch,
                   uint8_t **buf,
                   size_t *len) {
  struct udp_hdr *udp = (struct udp_hdr *) *dest;

  if (*dlen < sizeof(struct udp_hdr)) return -2;
  *dest += sizeof(struct udp_hdr); *dlen -= sizeof(struct udp_hdr);

  *nxt_hdr = IANA_UDP;

  // MUST be elided
  udp->len = 0;
  // MAY be elided if sufficient conditions are met
  udp->chksum = 0;

  /* decompress the ports */
  switch (dispatch & LOWPAN_NHC_UDP_PORT_MASK) {
  case LOWPAN_NHC_UDP_PORT_FULL:
    if (*len < 4) return -1;
    udp->srcport = htons(((*buf)[0] << 8) | (*buf)[1]);
    udp->dstport = htons(((*buf)[2] << 8) | (*buf)[3]);
    *buf += 4; *len -= 4;
    break;
  case LOWPAN_NHC_UDP_PORT_SRC_FULL:
    if (*len < 3) return -1;
    udp->srcport = htons(((*buf)[0] << 8) | (*buf)[1]);
    udp->dstport = htons((0xF0 << 8) | (*buf)[2]);
    *buf += 3; *len -= 3;
    break;
  case LOWPAN_NHC_UDP_PORT_DST_FULL:
    if (*len < 3) return -1;
    udp->srcport = htons((0xF0 << 8) | (*buf)[0]);
    udp->dstport = htons(((*buf)[1] << 8) | (*buf)[2]);
    *buf += 3; *len -= 3;
    break;
  case LOWPAN_NHC_UDP_PORT_SHORT:
    if (*len < 1) return -1;
    udp->srcport = htons((0xF0B0) | ((*buf)[0] >> 4));
    udp->dstport = 0xF0B0 | ((*buf)[0] & 0xf);
    udp->dstport = htons(udp->dstport);
    *buf += 1; *len -= 1;
    break;
  }

  if (!(dispatch & LOWPAN_NHC_UDP_CKSUM)) {
    if (*len < 2) return -1;
    udp->chksum = htons(((*buf)[0] << 8) | (*buf)[1]);
    *buf += 2; *len -= 2;
  }

  // Set the pointer to where the length field is so that it can be filled in
  // later.
  recon->r_app_len = &udp->len;

  return 0;
}

/**
 * Unpack an IPv6 extension header that has been compressed with LOWPAN_NHC
 *
 * Returns  1 if there is a NHC header after this one
 *          0 if there is not another LOWPAN_NHC header following this one.
 *         -1 if the source buffer is too short
 *         -2 if the dest buffer is too short
 *         -3 on other error.
 */
int unpack_nhc_ipv6_ext(uint8_t **dest,
                        size_t *dlen,
                        uint8_t **nxt_hdr,
                        uint8_t dispatch,
                        uint8_t **buf,
                        size_t *len) {

  struct ip6_ext *ext = (struct ip6_ext *) *dest;
  uint8_t length, extra;

  if (*dlen < sizeof(struct ip6_ext)) return -2;
  *dest += sizeof(struct ip6_ext); *dlen -= sizeof(struct ip6_ext);

  // decompress an ipv6 extension header

  // fill in the next header field of the previous header
  switch (dispatch & LOWPAN_NHC_EID_MASK) {
  case LOWPAN_NHC_EID_HOP:     **nxt_hdr = IPV6_HOP; break;
  case LOWPAN_NHC_EID_ROUTING: **nxt_hdr = IPV6_ROUTING; break;
  case LOWPAN_NHC_EID_FRAG:    **nxt_hdr = IPV6_FRAG; break;
  case LOWPAN_NHC_EID_DEST:    **nxt_hdr = IPV6_DEST; break;
  case LOWPAN_NHC_EID_MOBILE:  **nxt_hdr = IPV6_MOBILITY; break;
  case LOWPAN_NHC_EID_IPV6:
    /* if this happens we need to restart compression at the next byte... */
    **nxt_hdr = IPV6_IPV6; break;
  default:
    return -3;
  }

  // if the next header value is inline, copy that in.
  if (!(dispatch & LOWPAN_NHC_NH)) {
    if (*len < 1) return -1;
    ext->ip6e_nxt = (*buf)[0];
    *buf += 1; *len -= 1;
  }

  // Get the length of the extension header
  if (*len < 1) return -1;
  length = (*buf)[0];
  *buf += 1; *len -= 1;

  // Calculate the padding required after this extension header
  // The IPv6 length includes the next header and length bytes, whereas
  // the NHC length does not. Therefore, we add two.
  extra = (8 - ((length+2) % 8)) % 8;

  // Copy the extension header contents into the uncompressed buffer
  if (*dlen < length + extra) return -2;
  if (*len < length) return -1;
  memcpy(*dest, *buf, length);
  *dest += length; *dlen -= length;
  *buf += length; *len -= length;

  /* pad out to units of 8 octets if necessary */
  if (**nxt_hdr == IPV6_HOP || **nxt_hdr == IPV6_DEST) {
    if (extra == 1) {
      /* insert a Pad1 */
      (*dest)[0] = IPV6_TLV_PAD1;
      *dest += 1; *dlen -= 1;
    } else if (extra > 1) {
      (*dest)[0] = IPV6_TLV_PADN;
      (*dest)[1] = extra - 2;
      *dest += extra; *dlen -= extra;
    }
  }
  ext->ip6e_len = (((length+2) + extra) / 8) - 1;

  // Set the next header pointer to now point to this header's next header
  // byte.
  *nxt_hdr = &ext->ip6e_nxt;

  if (dispatch & LOWPAN_NHC_NH) {
    // The next header byte was elided. This means that there must be another
    // compressed NHC header after this on.
    return 1;
  }

  return 0;
}

/* Unpack all compressed lowpan headers that are remaining in the packet.
 *
 * @recon    Holds the uncompressed ipv6 packet
 * @dest     Buffer to insert the uncompressed headers
 * @destlen  Length of the destination buffer
 * @nxt_hdr  Pointer to the next header byte in ipv6 header
 * @buf      Source buffer
 * @len      Length of the source buffer
 *
 * Returns  0 on success
 *         -1 if the source buffer is incomplete
 *         -2 if the destination buffer is full
 */
int unpack_nhc_chain(struct lowpan_reconstruct *recon,
                     uint8_t **dest,
                     size_t *dlen,
                     uint8_t *nxt_hdr,
                     uint8_t **buf,
                     size_t *len) {
  int has_nhc = 1;
  uint8_t dispatch;
  int ret;

  do {
    recon->r_transport_header = *dest;

    if (*len < 1) return -1;
    dispatch = (*buf)[0];
    *buf += 1; *len -= 1;

    if ((dispatch & LOWPAN_NHC_IPV6_MASK) == LOWPAN_NHC_IPV6_PATTERN) {
      ret = unpack_nhc_ipv6_ext(dest, dlen, &nxt_hdr, dispatch, buf, len);
      if (ret < 0) return ret;

      if (ret == 0) {
        // No more headers to uncompress
        has_nhc = 0;
      }

    } else if ((dispatch & LOWPAN_NHC_UDP_MASK) == LOWPAN_NHC_UDP_PATTERN) {
      ret = unpack_nhc_udp(recon, dest, dlen, nxt_hdr, dispatch, buf, len);
      if (ret < 0) return ret;

      // There will not be another header to uncompress after the UDP header
      has_nhc = 0;

    } else {
      has_nhc = 0;
    }
  } while (has_nhc);

  return 0;
}

/* Unpack all of the lowpan headers from the buffer.
 *
 * @recon                The reconstruction struct to put stuff in.
 * @frame                The IEEE154 header
 * @buf                  The source buffer to uncompress
 * @len                  The length of the source buffer
 * @recalculate_checksum Return argument that notes whether stateful
 *                       compression was used
 * @unpacked_len         Return argument of the total number of bytes in the
 *                       uncompressed packet
 *
 * Returns 0 on success, -1 if the source buffer is too short, -2 if the
 * unpacked packet is greater than the recon struct, -3 on other error.
 */
int lowpan_unpack_headers(struct lowpan_reconstruct *recon,
                          struct ieee154_frame_addr *frame,
                          uint8_t **buf,
                          size_t *len,
                          uint8_t *recalculate_checksum,
                          uint16_t *unpacked_len) {
  uint8_t dispatch[2];
  int contexts[2] = {0, 0};
  uint8_t *dest = recon->r_buf;
  size_t dlen = recon->r_size;
  struct ip6_hdr *hdr = (struct ip6_hdr *) dest;
  int ret;

  *recalculate_checksum = 0;

  if (*len < 2) return -1;
  dispatch[0] = (*buf)[0];
  dispatch[1] = (*buf)[1];
  *buf += 2; *len -= 2;

  if (dlen < sizeof(struct ip6_hdr)) return -2;
  dest += sizeof(struct ip6_hdr); dlen -= sizeof(struct ip6_hdr);

  if ((dispatch[0] & LOWPAN_DISPATCH_BYTE_MASK) != LOWPAN_DISPATCH_BYTE_VAL) {
    return -3;
  }

  ret = unpack_context(dispatch[1], contexts, buf, len);
  if (ret < 0) return ret;

  // pull out the IP header fields
  ret = unpack_tcfl(hdr, dispatch[0], buf, len);
  if (ret < 0) return ret;
  ret = unpack_nh(hdr, dispatch[0], buf, len);
  if (ret < 0) return ret;
  ret = unpack_hlim(hdr, dispatch[0], buf, len);
  if (ret < 0) return ret;

  // source address is always unicast compressed
  ret = unpack_address(&hdr->ip6_src,
                       (dispatch[1] >> LOWPAN_IPHC_SAM_SHIFT),
                       contexts[0],
                       buf,
                       len,
                       &frame->ieee_src,
                       frame->ieee_dstpan,
                       recalculate_checksum);
  if (ret < 0) return ret;

  // destination address may use multicast address compression
  if (dispatch[1] & LOWPAN_IPHC_M) {
    ret = unpack_multicast(&hdr->ip6_dst,
                           (dispatch[1] >> LOWPAN_IPHC_DAM_SHIFT),
                           contexts[1],
                           buf,
                           len);
  } else {
    ret = unpack_address(&hdr->ip6_dst,
                         (dispatch[1] >> LOWPAN_IPHC_DAM_SHIFT),
                         contexts[1],
                         buf,
                         len,
                         &frame->ieee_dst,
                         frame->ieee_dstpan,
                         recalculate_checksum);
  }
  if (ret < 0) return ret;

  // IPv6 header is complete.
  // At this point, (might) need to decompress a chain of headers compressed
  // with LOWPAN_NHC
  if (dispatch[0] & LOWPAN_IPHC_NH_MASK) {
    ret = unpack_nhc_chain(recon,
                           &dest,
                           &dlen,
                           &hdr->ip6_nxt,
                           buf,
                           len);
    if (ret < 0) return ret;
  }

  // Copy any remaining payload into the unpack region
  if (dlen < *len) return -2;
  memcpy(dest, *buf, *len);
  dest += *len; dlen -= *len;
  buf += *len; *len = 0;

  // Set the total length of the uncompressed packet
  *unpacked_len = dest - recon->r_buf;

  return 0;
}
