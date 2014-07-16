/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
#ifndef _LIB6LOWPAN_H_
#define _LIB6LOWPAN_H_

#define UNUSED

#include <stdint.h>

#include "lib6lowpan-includes.h"
#include "ip.h"

/* utility macros */

#ifndef PC
#define memclr(ptr, len) memset((ptr), 0, (len))
// #define memcpy(dst, src, len) ip_memcpy((uint8_t *)dst, (uint8_t *)src, len)
// #define memmove(dst, src, len) ip_memcpy(dst, src, len)
uint8_t *ip_memcpy(uint8_t *dst0, const uint8_t *src0, uint16_t len) ;
#endif

uint16_t ieee154_hashaddr(ieee154_addr_t *addr);

/*
 * Fragmentation routines.
 */
struct packed_lowmsg {
  uint8_t headers;
  uint8_t len;
  uint8_t *data;
};

struct lowpan_reconstruct {
  uint16_t r_tag;            /* datagram label */
  uint16_t r_source_key;     /*  */
  uint16_t r_size;           /* the size of the packet we are reconstructing */
  uint8_t *r_buf;            /* the reconstruction location */
  uint16_t r_bytes_rcvd;     /* how many bytes from the packet we have
                              received so far */
  uint8_t  r_timeout;
  uint16_t *r_app_len;
  uint8_t  *r_transport_header;
  struct ip6_metadata       r_meta;
};

struct lowpan_ctx {
  uint16_t tag;    /* the label of the datagram */
  uint16_t offset; /* how far into the packet we have sent, in bytes */
};


enum {
  LOWMSG_MESH_HDR  = (1 << 0),
  LOWMSG_BCAST_HDR = (1 << 1),
  LOWMSG_FRAG1_HDR = (1 << 2),
  LOWMSG_FRAGN_HDR = (1 << 3),
  LOWMSG_NALP      = (1 << 4),
  LOWMSG_IPNH_HDR  = (1 << 5),
  LOWMSG_IPV6      = (1 << 6),
};

uint16_t getHeaderBitmap(struct packed_lowmsg *lowmsg);
/*
 * Return the length of the buffer required to pack lowmsg
 *  into a buffer.
 */

uint8_t *getLowpanPayload(struct packed_lowmsg *lowmsg);

uint8_t setupHeaders(struct packed_lowmsg *packed, uint16_t headers);

/*
 * Test if various protocol features are enabled
 */
uint8_t hasMeshHeader(struct packed_lowmsg *msg);
uint8_t hasBcastHeader(struct packed_lowmsg *msg);
uint8_t hasFrag1Header(struct packed_lowmsg *msg);
uint8_t hasFragNHeader(struct packed_lowmsg *msg);

/*
 * Mesh header fields
 *
 *  return FAIL if the message doesn't have a mesh header
 */
uint8_t getMeshHopsLeft(struct packed_lowmsg *msg, uint8_t *hops);
uint8_t getMeshOriginAddr(struct packed_lowmsg *msg, ieee154_saddr_t *origin);
uint8_t getMeshFinalAddr(struct packed_lowmsg *msg, ieee154_saddr_t *final);

uint8_t setMeshHopsLeft(struct packed_lowmsg *msg, uint8_t hops);
uint8_t setMeshOriginAddr(struct packed_lowmsg *msg, ieee154_saddr_t origin);
uint8_t setMeshFinalAddr(struct packed_lowmsg *msg, ieee154_saddr_t final);

/*
 * Broadcast header fields
 */
uint8_t getBcastSeqno(struct packed_lowmsg *msg, uint8_t *seqno);

uint8_t setBcastSeqno(struct packed_lowmsg *msg, uint8_t seqno);

/*
 * Fragmentation header fields
 */
uint8_t getFragDgramSize(struct packed_lowmsg *msg, uint16_t *size);
uint8_t getFragDgramTag(struct packed_lowmsg *msg, uint16_t *tag);
uint8_t getFragDgramOffset(struct packed_lowmsg *msg, uint8_t *size);

uint8_t setFragDgramSize(struct packed_lowmsg *msg, uint16_t size);
uint8_t setFragDgramTag(struct packed_lowmsg *msg, uint16_t tag);
uint8_t setFragDgramOffset(struct packed_lowmsg *msg, uint8_t size);


/*
 * extern functions -- must be declared by app somewhere else
 */
int lowpan_extern_match_context(struct in6_addr *addr, UNUSED uint8_t *ctx_id);
int lowpan_extern_read_context(struct in6_addr *addr, int context);


int pack_nhc_chain(uint8_t **dest, size_t *dlen, struct ip6_packet *packet);
/*
 * Pack the header fields of msg into buffer 'buf'.
 *  it returns the number of bytes written to 'buf', or zero if it encountered
 *  a problem.
 *
 * it will pack the IP header and all headers in the header chain of
 * msg into the buffer; the only thing it will not pack is the
 * payload.
 *
 * @packet the message to be packet
 * @frame link-layer address information about the packet
 * @buf   a buffer to write the headers into
 * @cnt   length of the buffer
 * @return the number of
 */
uint8_t *lowpan_pack_headers(struct ip6_packet *packet,
                             struct ieee154_frame_addr *frame,
                             uint8_t *buf, size_t cnt);


int lowpan_unpack_headers(struct lowpan_reconstruct *recon,
                          struct ieee154_frame_addr *frame,
                          uint8_t **buf,
                          size_t *len,
                          uint8_t *recalculate_checksum,
                          uint16_t *unpacked_len);

/*
 *  this function writes the next fragment which needs to be sent into
 *  the buffer passed in.  It updates the structures in process to
 *  reflect how much of the packet has been sent so far.
 *
 *  if the packet does not require fragmentation, this function will
 *  not insert a fragmentation header and will merely compress the
 *  headers into the packet.
 *
 */
int lowpan_frag_get(uint8_t *frag, size_t len,
                    struct ip6_packet *packet,
                    struct ieee154_frame_addr *frame,
                    struct lowpan_ctx *ctx);

int lowpan_recon_start(struct ieee154_frame_addr *frame_addr,
                       struct lowpan_reconstruct *recon,
                       uint8_t *pkt, size_t len);
int lowpan_recon_add(struct lowpan_reconstruct *recon,
                     uint8_t *pkt, size_t len);

enum {
  T_FAILED1 = 0,
  T_FAILED2 = 1,
  T_UNUSED =  2,
  T_ACTIVE =  3,
  T_ZOMBIE =  4,
};

/* uint8_t* getLinkLocalPrefix(); */
#endif
