#ifndef _INTERNAL_H
#define _INTERNAL_H

#include <stdint.h>
#include "lib6lowpan-includes.h"
#include "lib6lowpan.h"
#include "ip.h"
#include "Ieee154.h"

/* Internal function prototypes for unit testing
 * this way gcc can check against the right prototype.
 */

/* packing */
int bit_range_zero_p(uint8_t *buf, int start, int end);
inline uint8_t *pack_tcfl(uint8_t *buf, struct ip6_hdr *hdr, uint8_t *dispatch);
inline uint8_t *pack_nh(uint8_t *buf, struct ip6_hdr *hdr, uint8_t *dispatch);
inline uint8_t *pack_hlim(uint8_t *buf, struct ip6_hdr *hdr, uint8_t *dispatch);
uint8_t *pack_address(uint8_t *buf, struct in6_addr *addr, int context_match_len,
                      ieee154_addr_t *l2addr, ieee154_panid_t pan, uint8_t *flags);
uint8_t *pack_multicast(uint8_t *buf, struct in6_addr *addr, uint8_t *flags);
int pack_udp(uint8_t *buf, size_t cnt, struct ip6_packet *packet, int offset);
int pack_ipnh(uint8_t *dest, size_t cnt, uint8_t *type, struct ip6_packet *packet, int offset);
int pack_nhc_chain(uint8_t **dest, size_t cnt, struct ip6_packet *packet);
uint8_t *pack_ieee154_header(uint8_t *buf, size_t cnt,
                             struct ieee154_frame_addr *frame);
uint8_t * lowpan_pack_headers(struct ip6_packet *packet,
                              struct ieee154_frame_addr *frame,
                              uint8_t *buf, size_t cnt);

/* unpacking */
uint8_t *unpack_ieee154_hdr(uint8_t *buf, struct ieee154_frame_addr *frame);
uint8_t *unpack_tcfl(struct ip6_hdr *hdr, uint8_t dispatch, uint8_t *buf);
uint8_t *unpack_nh(struct ip6_hdr *hdr, uint8_t dispatch, uint8_t *buf);
uint8_t *unpack_hlim(struct ip6_hdr *hdr, uint8_t dispatch, uint8_t *buf);
uint8_t *unpack_address(struct in6_addr *addr, uint8_t dispatch, 
                        int context, uint8_t *buf,
                        ieee154_addr_t *frame, ieee154_panid_t pan);
uint8_t *unpack_multicast(struct in6_addr *addr, uint8_t dispatch, 
                          int context, uint8_t *buf);
uint8_t *unpack_udp(uint8_t *dest, uint8_t *nxt_hdr, uint8_t *buf);
uint8_t *unpack_ipnh(uint8_t *dest, size_t cnt, uint8_t *nxt_hdr, uint8_t *buf);
uint8_t *unpack_nhc_chain(struct lowpan_reconstruct *recon,
                          uint8_t **dest, size_t cnt, 
                          uint8_t *nxt_hdr, uint8_t *buf);

#endif
