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

#include <stdint.h>
#include <stddef.h>

#include "6lowpan.h"
#include "ip.h"

#ifdef __TARGET_mips__
// #warning "Using big endian byte order"
#define ntoh16(X)   (X)
#define hton16(X)   (X)
#define ntoh32(X)   (X)
#define hton32(X)   (X)
#define leton16(X)  (((((uint16_t)(X)) << 8) | ((uint16_t)(X) >> 8)) & 0xffff)
#define htole16(X)  leton16(X)
#else
// #warning "Using little endian byte order"
#define ntoh16(X)   (((((uint16_t)(X)) >> 8) | ((uint16_t)(X) << 8)) & 0xffff)
#define hton16(X)   (((((uint16_t)(X)) << 8) | ((uint16_t)(X) >> 8)) & 0xffff)
#define leton16(X)  hton16(X)
#define htole16(X)  (X)
#define ntoh32(X)   ((((uint32_t)(X) >> 24) & 0x000000ff)| \
                     ((((uint32_t)(X) >> 8)) & 0x0000ff00) | \
                     ((((uint32_t)(X) << 8)) & 0x00ff0000) | \
                     ((((uint32_t)(X) << 24)) & 0xff000000))

#define hton32(X)   ((((uint32_t)(X) << 24) & 0xff000000)| \
                     ((((uint32_t)(X) << 8)) & 0x00ff0000) | \
                     ((((uint32_t)(X) >> 8)) & 0x0000ff00) | \
                     ((((uint32_t)(X) >> 24)) & 0x000000ff))
#endif


#define ntohs(X) ntoh16(X)
#define htons(X) hton16(X)

#define ntohl(X) ntoh32(X)
#define htonl(X) hton32(X)


#ifdef DEF_MEMCPY
#define memcpy(X,Y,Z) ip_memcpy(X,Y,Z)
#endif

/*
 * This interface implements the 6loWPAN header structures.  Support
 * for the HC1 and HC2 compressed IP and UDP headers is also
 * available, and the interface is presented in lib6lowpanIP.h.
 *
 */

// only 16-bit address handling modes
#define __6LOWPAN_16BIT_ADDRESS

/*
 *  Library implementation of packing of 6lowpan packets.  
 *
 *  This should allow uniform code treatment between pc and mote code;
 *  the goal is to write ANSI C here...  This means no nx_ types,
 *  unfortunately.
 */

/*
 * 6lowpan header functions
 */

uint16_t getHeaderBitmap(packed_lowmsg_t *lowmsg);
/*
 * Return the length of the buffer required to pack lowmsg
 *  into a buffer.
 */

uint8_t *getLowpanPayload(packed_lowmsg_t *lowmsg);

/*
 * Initialize the header bitmap in 'packed' so that
 *  we know how long the headers are.
 *
 * @return FAIL if the buffer is not long enough.
 */
uint8_t setupHeaders(packed_lowmsg_t *packed, uint16_t headers);

/*
 * Test if various protocol features are enabled
 */
uint8_t hasMeshHeader(packed_lowmsg_t *msg);
uint8_t hasBcastHeader(packed_lowmsg_t *msg);
uint8_t hasFrag1Header(packed_lowmsg_t *msg);
uint8_t hasFragNHeader(packed_lowmsg_t *msg);

/*
 * Mesh header fields
 *
 *  return FAIL if the message doesn't have a mesh header
 */
uint8_t getMeshHopsLeft(packed_lowmsg_t *msg, uint8_t *hops);
uint8_t getMeshOriginAddr(packed_lowmsg_t *msg, hw_addr_t *origin);
uint8_t getMeshFinalAddr(packed_lowmsg_t *msg, hw_addr_t *final);

uint8_t setMeshHopsLeft(packed_lowmsg_t *msg, uint8_t hops);
uint8_t setMeshOriginAddr(packed_lowmsg_t *msg, hw_addr_t origin);
uint8_t setMeshFinalAddr(packed_lowmsg_t *msg, hw_addr_t final);

/*
 * Broadcast header fields
 */
uint8_t getBcastSeqno(packed_lowmsg_t *msg, uint8_t *seqno);

uint8_t setBcastSeqno(packed_lowmsg_t *msg, uint8_t seqno);

/*
 * Fragmentation header fields
 */
uint8_t getFragDgramSize(packed_lowmsg_t *msg, uint16_t *size);
uint8_t getFragDgramTag(packed_lowmsg_t *msg, uint16_t *tag);
uint8_t getFragDgramOffset(packed_lowmsg_t *msg, uint8_t *size);

uint8_t setFragDgramSize(packed_lowmsg_t *msg, uint16_t size);
uint8_t setFragDgramTag(packed_lowmsg_t *msg, uint16_t tag);
uint8_t setFragDgramOffset(packed_lowmsg_t *msg, uint8_t size);

/*
 * IP header compression functions
 *
 */
int getCompressedLen(packed_lowmsg_t *pkt);

/*
 * Pack the header fields of msg into buffer 'buf'.
 *  it returns the number of bytes written to 'buf', or zero if it encountered a problem.
 *
 * it will pack the IP header and all headers in the header chain of
 * msg into the buffer; the only thing it will not pack is the
 * payload.
 */
uint8_t packHeaders(struct split_ip_msg *msg,
                    uint8_t *buf, uint8_t len);
/*
 * Unpack the packed data from pkt into dest.
 *
 * It turns out that we need to keep track of a lot of different
 * locations in order to be able to unpack and forward efficiently.
 * If we don't save these during the unpack, we end up reconstructing
 * them in various places so it's less error-prone to compute them
 * while we're parsing the packed fields.
 */
typedef struct {
  // the final header in the header chain; should be the transport header
  uint8_t nxt_hdr;
  // a pointer to the point in the source where we stopped unpacking
  uint8_t *payload_start;
  // a pointer to the point in the destination right after all headers
  uint8_t *header_end;
  // the total, uncompressed length of the headers which were unpacked
  uint8_t payload_offset;
  // points to the hop limit field of the packet message
  uint8_t *hlim;
  // points to the tranport header in the destination region, 
  //  if it was within the unpacked region header.
  //  if it was not, it is the same as header_end
  uint8_t *transport_ptr;
  // points to the source header within the packed fields, IF it contains one.
  struct source_header *sh;
  struct rinstall_header *rih;
} unpack_info_t;

uint8_t *unpackHeaders(packed_lowmsg_t *pkt, unpack_info_t *u_info,
                       uint8_t *dest, uint16_t len);

/*
 * Fragmentation routines.
 */

extern uint16_t lib6lowpan_frag_tag;

typedef struct {
  uint16_t tag;            /* datagram label */
  uint16_t size;           /* the size of the packet we are reconstructing */
  void    *buf;            /* the reconstruction location */
  uint16_t bytes_rcvd;     /* how many bytes from the packet we have
                              received so far */
  uint8_t timeout;
  uint8_t *transport_hdr;
  struct ip_metadata metadata;
} reconstruct_t;

typedef struct {
  uint16_t tag;    /* the label of the datagram */
  uint16_t offset; /* how far into the packet we have sent, in bytes */
} fragment_t;


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
uint8_t getNextFrag(struct split_ip_msg *msg, fragment_t *progress,
                    uint8_t *buf, uint16_t len);


enum {
  T_FAILED1 = 0,
  T_FAILED2 = 1,
  T_UNUSED =  2,
  T_ACTIVE =  3,
  T_ZOMBIE =  4,
};

uint8_t* getLinkLocalPrefix();
#endif
