/* Implementation of draft-ietf-6lowpan-hc-06 */
/* @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu> */

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

/* packs the Traffic Class and Flow Label fields as described in the internet draft */
/* @buf the buffer to write any anyline fields to */
/* @hdr the IPv6 header being compressed; this function only examines the first four octets */
/* @dispatch the octet corresponding to the first octet of the IPHC dispatch value */
/*      modified to reflect the packing of the fields */
inline uint8_t *pack_tcfl(uint8_t *buf, struct ip6_hdr *hdr, uint8_t *dispatch) {
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

inline uint8_t *pack_hlim(uint8_t *buf, struct ip6_hdr *hdr, uint8_t *dispatch) {
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

/* packs all non-multicast addresses */
/* @buf output buffer */
/* @addr the ipv6 address to be compressed */
/* @context_match_len if a context matches, how long the match is.  must be multiple of 8 */
/* @l2addr the link-layer address correspoinding to the address (source or destination) */
/* @pan the destination pan ID */
/* @flags return argument; which address mode was selected */
uint8_t *pack_address(uint8_t *buf, struct in6_addr *addr, int context_match_len,
                      ieee154_addr_t *l2addr, ieee154_panid_t pan, uint8_t *flags) {
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
    } else if (/* maybe it's a 16-bit address with the IID derived from the PANID + address */
               (addr->s6_addr16[4] == htons(letohs(pan)) &&
                addr->s6_addr16[5] == htons(0x00ff) &&
                addr->s6_addr16[6] == htons(0xfe00) &&
                (((l2addr->ieee_mode == IEEE154_ADDR_SHORT) && 
                  addr->s6_addr16[7] == htons(letohs(l2addr->i_saddr))))) ||
               /* no?  Maybe it's just a straight-up 64-bit EUI64 */
                 ((l2addr->ieee_mode == IEEE154_ADDR_EXT) && 
                  (memcmp(&addr->s6_addr[8], &l2addr->i_laddr.data, 8) == 0))) {
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
    } else if (bit_range_zero_p(&addr->s6_addr[0], context_match_len, 112) == 0) {
      *flags |= LOWPAN_IPHC_AM_16;
      memcpy(buf, &addr->s6_addr[14], 2);
      extra = 2;
    } else if (bit_range_zero_p(&addr->s6_addr[0], context_match_len, 64) == 0) {
      *flags |= LOWPAN_IPHC_AM_64;
      memcpy(buf, &addr->s6_addr[8], 8);
      extra = 8;
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

/* never pack the ports */
int pack_udp(uint8_t *buf, size_t cnt, struct ip6_packet *packet, int offset) {
  struct udp_hdr udp;

  if (cnt < 7) {
    return -1;
  }
  
  if (iov_read(packet->ip6_data, offset, sizeof(struct udp_hdr), (void *)&udp) != 
      sizeof(struct udp_hdr)) {
    return -1;
  }

  *buf = LOWPAN_NHC_UDP_PATTERN | LOWPAN_NHC_UDP_PORT_FULL;
  memcpy(buf + 1, &udp.srcport, 4);
  memcpy(buf + 5, &udp.chksum, 2);
  return 7;
}

int pack_ipnh(uint8_t *dest, size_t cnt, uint8_t *type, struct ip6_packet *packet, int offset) {
  struct ip6_ext ext;

  /* read the ipv6 extension header out for processing */
  if (iov_read(packet->ip6_data, offset, 2, (void *)&ext) != 2)
    return -1;

  if (ext.ip6e_len > cnt)
    return -1;

  *dest = LOWPAN_NHC_IPV6_PATTERN;
  switch (*type) {
  case IPV6_HOP:
    *dest |= LOWPAN_NHC_EID_HOP; break;
  case IPV6_ROUTING:
    *dest |= LOWPAN_NHC_EID_ROUTING; break;
  case IPV6_FRAG:
    *dest |= LOWPAN_NHC_EID_FRAG; break;
  case IPV6_DEST:
    *dest |= LOWPAN_NHC_EID_DEST; break;
  case IPV6_MOBILITY:
    *dest |= LOWPAN_NHC_EID_MOBILE; break;
  default:
    return -1;
  }

  /* store the next header type */
  /*  if it's compressable, we will compress it */
  *type = ext.ip6e_nxt;
  if (ext.ip6e_nxt == IPV6_HOP  || ext.ip6e_nxt == IPV6_ROUTING  || ext.ip6e_nxt == IPV6_FRAG ||
      ext.ip6e_nxt == IPV6_DEST || ext.ip6e_nxt == IPV6_MOBILITY || ext.ip6e_nxt == IPV6_IPV6 ||
      ext.ip6e_nxt == IANA_UDP) {
    *dest |= LOWPAN_NHC_NH;
  }

  dest ++;
  *dest++ = ext.ip6e_len;

  /* copy the payload */
  if (iov_read(packet->ip6_data, offset + 2, ext.ip6e_len - 2, dest) != ext.ip6e_len - 2)
    return -1;

  return ext.ip6e_len;
}

int pack_nhc_chain(uint8_t **dest, size_t cnt, struct ip6_packet *packet) {
  uint8_t nxt = packet->ip6_hdr.ip6_nxt;
  int offset = 0, rv;
  /* @return offset is the offset into the unpacked ipv6 datagram */
  /* dest is updated to show how far we have gotten in the packed data */

  
  while (nxt == IPV6_HOP  || nxt == IPV6_ROUTING  || nxt == IPV6_FRAG ||
         nxt == IPV6_DEST || nxt == IPV6_MOBILITY || nxt == IPV6_IPV6) {
    rv = pack_ipnh(*dest, cnt, &nxt,  packet, offset);

    if (rv < 0) return -1;
    /* it just so happens that LOWPAN_IPNH doesn't change the length
       of the headers */
    *dest  += rv;
    offset += rv;
    cnt    -= rv;
  }

  if (nxt == IANA_UDP) {
    rv = pack_udp(*dest, cnt, packet, offset);

    if (rv < 0) return -1;
    offset += sizeof(struct udp_hdr);
    *dest  += rv;
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
  /*   2. first, pack the IP headers and any other compressible header into the frame */
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
  ctx_match_length = lowpan_extern_match_context(&packet->ip6_hdr.ip6_src, &temp_dispatch);
  temp_dispatch = 0;
  buf = pack_address(buf, &packet->ip6_hdr.ip6_src, ctx_match_length,
                     &frame->ieee_src, frame->ieee_dstpan, &temp_dispatch);
  *(dispatch+1) |= temp_dispatch << LOWPAN_IPHC_SAM_SHIFT;

  if (packet->ip6_hdr.ip6_dst.s6_addr[0] != 0xff) {
    /* not multicast */
    ctx_match_length = lowpan_extern_match_context(&packet->ip6_hdr.ip6_src, &temp_dispatch);
    temp_dispatch = 0;
    buf = pack_address(buf, &packet->ip6_hdr.ip6_dst, ctx_match_length,
                       &frame->ieee_dst, frame->ieee_dstpan, &temp_dispatch);
    *(dispatch+1) |= temp_dispatch << LOWPAN_IPHC_DAM_SHIFT;
  } else {
    /* multicast */
    buf = pack_multicast(buf, &packet->ip6_hdr.ip6_dst, &temp_dispatch);
    *(dispatch + 1) |= (temp_dispatch << LOWPAN_IPHC_DAM_SHIFT) | LOWPAN_IPHC_AM_M;
  }
  
  return buf;
}

uint8_t *unpack_tcfl(struct ip6_hdr *hdr, uint8_t dispatch, uint8_t *buf) {
  uint8_t  fl[3] = {0,0,0}; 
  uint8_t  tc = 0;

  switch (dispatch & LOWPAN_IPHC_TF_MASK) {
  case LOWPAN_IPHC_TF_ECN_DSCP:
    tc  = ((*buf) >> 6) & 0xff;
    tc |= ((*buf) << 2) & 0xff;
    buf += 1;
    break;
  case LOWPAN_IPHC_TF_ECN_FL:
    tc = ((*buf) >> 6) & 0xff;
    fl[2] = buf[0] & 0x0f;
    fl[1] = buf[1];
    fl[0] = buf[2];
    buf += 3;
    break;
  case LOWPAN_IPHC_TF_ECN_DSCP_FL:
    tc  = ((*buf) >> 6) & 0xff;
    tc |= ((*buf) << 2) & 0xff;
    fl[2] = buf[1] & 0x0f;
    fl[1] = buf[2];
    fl[0] = buf[3];
    buf += 4;
    break;
  }

  hdr->ip6_flow = htonl(((uint32_t)0x6 << 28) | 
                        ((uint32_t)tc << 20) | 
                        ((uint32_t)fl[2] << 16) | 
                        ((uint32_t)fl[1] << 8) | fl[0]);
  return buf;
}

uint8_t *unpack_nh(struct ip6_hdr *hdr, uint8_t dispatch, uint8_t *buf) {
  if ((dispatch & LOWPAN_IPHC_NH_MASK) == LOWPAN_IPHC_NH_INLINE) {
    hdr->ip6_nxt = *buf;
    return buf + 1;
  } else {
    return buf;
  }
}

uint8_t *unpack_hlim(struct ip6_hdr *hdr, uint8_t dispatch, uint8_t *buf) {
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
    hdr->ip6_hlim = *buf;
    return buf + 1;
  }
  return buf;
}

uint8_t *unpack_address(struct in6_addr *addr, uint8_t dispatch, 
                        int context, uint8_t *buf,
                        ieee154_addr_t *frame, ieee154_panid_t pan) {
  memset(addr, 0, 16);
  if(!((dispatch & LOWPAN_IPHC_AC_CONTEXT))) {
    /* stateless compression */
    switch (dispatch & LOWPAN_IPHC_AM_MASK) {
    case LOWPAN_IPHC_AM_128:
      memcpy(addr, buf, 16);
      return buf + 16;
    case LOWPAN_IPHC_AM_64:
      addr->s6_addr16[0] = htons(0xfe80);
      memcpy(&addr->s6_addr[8], buf, 8);
      return buf + 8;
    case LOWPAN_IPHC_AM_16:
      addr->s6_addr16[0] = htons(0xfe80);
      memcpy(&addr->s6_addr[14], buf, 2);
      return buf + 2;
    default:
      addr->s6_addr16[0] = htons(0xfe80);
      if (frame->ieee_mode == IEEE154_ADDR_EXT) {
        memcpy(&addr->s6_addr[8], frame->i_laddr.data, 8);
      } else {
        addr->s6_addr16[4] = leton16(pan);
        addr->s6_addr[11] = 0xff;
        addr->s6_addr[12] = 0xfe;
        addr->s6_addr16[7] = leton16(frame->i_saddr);
      }
      return buf;
    }
  } else {
    /* context-based compression */
    if ((dispatch & LOWPAN_IPHC_AM_MASK) == LOWPAN_IPHC_AM_128) {
      // unspecified address ::
      return buf;
    } else {
      lowpan_extern_read_context(addr, context);
      switch (dispatch & LOWPAN_IPHC_AM_MASK) {
      case LOWPAN_IPHC_AM_64:
        memcpy(&addr->s6_addr[8], buf, 8);
        return buf + 8;
      case LOWPAN_IPHC_AM_16:
        memcpy(&addr->s6_addr[14], buf, 2);
        return buf + 2;
      case LOWPAN_IPHC_AM_0:
        // not clear how to use this:
        //  "and 'possibly' link-layer addresses"
        return buf;
      }
    }
  }
  return NULL;
}

uint8_t *unpack_multicast(struct in6_addr *addr, uint8_t dispatch, 
                          int context, uint8_t *buf) {
  memset(addr->s6_addr, 0, 16);

  if (!(dispatch & LOWPAN_IPHC_AC_CONTEXT)) {
    int amount;
    switch (dispatch & LOWPAN_IPHC_AM_MASK) {
    case LOWPAN_IPHC_AM_M_128:
      memcpy(addr->s6_addr, buf, 16);
      return buf+ 16;
    case LOWPAN_IPHC_AM_M_48:
      amount = 5;
      goto copy;
    case LOWPAN_IPHC_AM_M_32:
      amount = 3;
    copy:
      addr->s6_addr[0] = 0xff;
      addr->s6_addr[1] = buf[0];
      memcpy(&addr->s6_addr[16-amount], buf + 1, amount);
      return buf + 1 + amount;
    case LOWPAN_IPHC_AM_M_8:
      addr->s6_addr16[0] = htons(0xff02);
      addr->s6_addr[15]  = buf[0];
      return buf + 1;
    }
  } else {
    // stateful multicast compression
    // all you need to do is read in the context here...
  }
  return NULL;
}

uint8_t *unpack_udp(uint8_t *dest, uint8_t *nxt_hdr, uint8_t *buf) {
  struct udp_hdr *udp = (struct udp_hdr *)dest;
  uint8_t dispatch = *buf++;

  *nxt_hdr = IANA_ICMP;

  // MUST be elided  
  udp->len = 0;
  // MAY be elided if sufficient conditions are met
  udp->chksum = 0;

  /* decompress the ports */
  switch (dispatch & LOWPAN_NHC_UDP_PORT_MASK) {
  case LOWPAN_NHC_UDP_PORT_FULL:
    udp->srcport = htons((buf[0] << 8) | buf[1]);
    udp->dstport = htons((buf[2] << 8) | buf[3]);
    buf += 4;
    break;
  case LOWPAN_NHC_UDP_PORT_SRC_FULL:
    udp->srcport = htons((buf[0] << 8) | buf[1]);
    udp->dstport = htons((0xF0 << 8) | buf[2]);
    buf += 3;
    break;
  case LOWPAN_NHC_UDP_PORT_DST_FULL:
    udp->srcport = htons((0xF0 << 8) | buf[0]);
    udp->dstport = htons((buf[1] << 8) | buf[2]);
    buf += 3;
    break;
  case LOWPAN_NHC_UDP_PORT_SHORT:
    udp->srcport = htons((0xF0B0) | (buf[0] >> 4));
    udp->dstport = 0xF0B0 | (buf[0] & 0xf);
    udp->dstport = htons(udp->dstport);
    buf += 1;
    break;
  }

  if (!(dispatch & LOWPAN_NHC_UDP_CKSUM)) {
    udp->chksum = htons((buf[0] << 8) | buf[1]);
    buf += 2;
  }

  return buf;
}

/**
 * Unpack a single header that has been encoded using LOWPAN_NHC
 *  compression 
 *
 * NOTE: in order simplify application support, this function does NOT
 *  convert the length field of ip extension headers to the form
 *  required by RFC2460: that is, the length value remains in units of
 *  octets.  It is expected that all software within a 6lowpan network
 *  will expect this to be the case; edge routers communicating with
 *  the outside world should take care to convert the length octet
 *  when such packets are received, including removing any necessary
 *  padding options.
 */
uint8_t *unpack_ipnh(uint8_t *dest, size_t cnt, uint8_t *nxt_hdr, uint8_t *buf) {
  if (((*buf) & LOWPAN_NHC_IPV6_MASK) == LOWPAN_NHC_IPV6_PATTERN) {
    struct ip6_ext *ext = (struct ip6_ext *)dest;
    uint8_t length;
    // decompress an ipv6 extension header

    // fill in the next header field of the previous header
    switch ((*buf) & LOWPAN_NHC_EID_MASK) {
    case LOWPAN_NHC_EID_HOP:
     *nxt_hdr = IPV6_HOP; break;
    case LOWPAN_NHC_EID_ROUTING:
      *nxt_hdr = IPV6_ROUTING; break;
    case LOWPAN_NHC_EID_FRAG:
      *nxt_hdr = IPV6_FRAG; break;
    case LOWPAN_NHC_EID_DEST:
      *nxt_hdr = IPV6_DEST; break;
    case LOWPAN_NHC_EID_MOBILE:
      *nxt_hdr = IPV6_MOBILITY; break;
    case LOWPAN_NHC_EID_IPV6:
      /* ja if this happens we need to restart compression at the next byte... */
      *nxt_hdr = IPV6_IPV6; break;
    default:
      return NULL;
    }

    // if the next header value is inline, copy that in.
    if (!((*buf) & LOWPAN_NHC_NH)) {
      buf ++;
      ext->ip6e_nxt = *buf;
    }
    buf += 1;
    length = *buf++;

    if (cnt < length - 2)
      return NULL;

    // buf now points at the start of the extension header data
    memcpy(dest + 2, buf, length - 2);
    ext->ip6e_len = length;

    return buf + length - 2;
  } else if (((*buf) & LOWPAN_NHC_UDP_MASK) == LOWPAN_NHC_UDP_PATTERN) {
    // packed UDP header
    return unpack_udp(dest, nxt_hdr, buf);
  }
  return NULL;
}

uint8_t *unpack_nhc_chain(struct lowpan_reconstruct *recon,
                          uint8_t **dest, size_t cnt, 
                          uint8_t *nxt_hdr, uint8_t *buf) {
  uint8_t *dispatch;
  int has_nhc = 1;

  do {
    dispatch = buf;
    buf = unpack_ipnh(*dest, cnt, nxt_hdr, buf);

    if (!buf) return NULL;

    if (((*dispatch & LOWPAN_NHC_IPV6_MASK) == LOWPAN_NHC_IPV6_PATTERN)) {
      struct ip6_ext *ext = (struct ip6_ext *)*dest;
      /* need to update dest */
      *dest += ext->ip6e_len;
      cnt  -= ext->ip6e_len;

      if ((*dispatch & LOWPAN_NHC_NH) && ext->ip6e_len > 0) { 
        nxt_hdr = &ext->ip6e_nxt;
      } else {
        has_nhc = 0; 
      }
    } else if (((*dispatch) & LOWPAN_NHC_UDP_MASK) == LOWPAN_NHC_UDP_PATTERN) {
      struct udp_hdr *udp = (struct udp_hdr *)*dest;
      recon->r_app_len = &udp->len;
      *nxt_hdr = IANA_UDP;
      has_nhc = 0;
      *dest += sizeof(struct udp_hdr);
    } else { has_nhc = 0; }
  } while (has_nhc);
  return buf;
}

uint8_t *lowpan_unpack_headers(struct lowpan_reconstruct *recon,
                               struct ieee154_frame_addr *frame,
                               uint8_t *buf, size_t cnt) {
  uint8_t *dispatch, *unpack_start = buf, *unpack_end;
  int contexts[2] = {0, 0};
  uint8_t *dest = recon->r_buf;
  size_t dst_cnt = recon->r_size;
  struct ip6_hdr *hdr = (struct ip6_hdr *)dest;

  dispatch = buf;
  buf += 2;

  if (((*dispatch) & LOWPAN_DISPATCH_BYTE_MASK) != LOWPAN_DISPATCH_BYTE_VAL) {
    return NULL;
  }

  /* extend the dispatch block if the context extension is present */
  if ((*(dispatch + 1) & LOWPAN_IPHC_CID_MASK) == LOWPAN_IPHC_CID_PRESENT) {
    contexts[0] = (*buf >> 4) & 0xf;
    contexts[1] = (*buf) & 0xf;
    buf += 1;
  }

  /* pull out the IP header fields */
  buf = unpack_tcfl(hdr, *dispatch, buf);
  buf = unpack_nh(hdr, *dispatch, buf);
  buf = unpack_hlim(hdr, *dispatch, buf);
  
  /* source address is always unicast compressed */
  // printf("unpack source: %p (%x)\n", buf, *buf);
  buf = unpack_address(&hdr->ip6_src,
                       ((*(dispatch + 1) >> LOWPAN_IPHC_SAM_SHIFT)), 
                       contexts[0], 
                       buf,
                       &frame->ieee_src,
                       frame->ieee_dstpan);
  if (!buf) {
    return NULL;
  }

  /* destination address may use multicast address compression */
  if (*(dispatch + 1) & LOWPAN_IPHC_M) {
    // printf("unpack multicast: %p\n", buf);
    buf = unpack_multicast(&hdr->ip6_dst,
                           ((*(dispatch + 1) >> LOWPAN_IPHC_DAM_SHIFT)), 
                           contexts[1],
                           buf);
    // printf("unpack multicast: %p (%x)\n", buf, *buf);
  } else {
    buf = unpack_address(&hdr->ip6_dst,
                         ((*(dispatch + 1) >> LOWPAN_IPHC_DAM_SHIFT)), 
                         contexts[1],
                         buf,
                         &frame->ieee_dst,
                         frame->ieee_dstpan);
  }
  if (!buf) {
    return NULL;
  }

  /* IPv6 header is complete */
  /*   at this point, (might) need to decompress a chain of headers
       compressed with LOWPAN_NHC */
  unpack_end = (uint8_t *)(hdr + 1);
  if ((*dispatch) & LOWPAN_IPHC_NH_MASK) {
    buf = unpack_nhc_chain(recon,
                           &unpack_end, 
                           dst_cnt - sizeof(struct ip6_hdr),
                           &hdr->ip6_nxt, 
                           buf);
    if (!buf) {
      return NULL;
    }
  }


  /* copy any remaining payload into the unpack region */
  memcpy(unpack_end, buf, cnt - (buf - unpack_start));
  
  /* return a pointer to the end of the unpacked data */
  return unpack_end + (cnt - (buf - unpack_start));
}
