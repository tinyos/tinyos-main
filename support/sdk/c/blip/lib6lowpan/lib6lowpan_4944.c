/*
 * "Copyright (c) 2008,2010 The Regents of the University  of California.
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
#include "lib6lowpan.h"
#include "6lowpan.h"
#include "nwbyte.h"

/*
 *  Library implementation of packing of 6lowpan packets.  
 *
 *  This should allow uniform code treatment between pc and mote code;
 *  the goal is to write ANSI C here...  This means no nx_ types,
 *  unfortunately.
 *
 *  Accessing fields programtically is probably a little less
 *  efficient, but that can be improved.  By precomputing the packet
 *  headers present, we can make the overhead not too bad.  The #1
 *  goal of this library is portability and readability.
 *
 *  The broadcast and mesh headers may or may not be useful, and are
 *  off by default to reduce code size.  Removing them reduces the
 *  library size by about 600 bytes.
 */


/*
 * Return the length (in bytes) of the buffer required to pack lowmsg
 * into a buffer.
 */
inline uint8_t *getLowpanPayload(struct packed_lowmsg *lowmsg) {
  uint8_t len = 0;
#if LIB6LOWPAN_FULL
  if (lowmsg->headers & LOWMSG_MESH_HDR)
    len += LOWMSG_MESH_LEN;
  if (lowmsg->headers & LOWMSG_BCAST_HDR)
    len += LOWMSG_BCAST_LEN;
#endif
  if (lowmsg->headers & LOWMSG_FRAG1_HDR)
    len += LOWMSG_FRAG1_LEN;
  if (lowmsg->headers & LOWMSG_FRAGN_HDR)
    len += LOWMSG_FRAGN_LEN;
  return lowmsg->data + len;
}

/*
 * Return a bitmap indicating which lowpan headers are
 *  present in the message pointed to by lowmsg.
 *
 */
inline uint16_t getHeaderBitmap(struct packed_lowmsg *lowmsg) {
  uint16_t headers = 0;
  uint8_t *buf = lowmsg->data;
  int16_t len = lowmsg->len;
  if (buf == NULL) return headers;

  if (len > 0 && ((*buf) >> 6) == LOWPAN_NALP_PATTERN) {
    return LOWMSG_NALP;
  }
  
#if LIB6LOWPAN_FULL
  if (len > 0 && ((*buf) >> 6) == LOWPAN_MESH_PATTERN) {
    if (!(*buf & LOWPAN_MESH_V_MASK) ||
        !(*buf & LOWPAN_MESH_F_MASK)) {
      // we will not parse a packet with 64-bit addressing.
      return LOWMSG_NALP;
    }
    headers |= LOWMSG_MESH_HDR;
    buf += LOWMSG_MESH_LEN;
    len -= LOWMSG_MESH_LEN;
  }
  if (len > 0 && (*buf) == LOWPAN_BCAST_PATTERN) {
    headers |= LOWMSG_BCAST_HDR;
    buf += LOWMSG_BCAST_LEN;
    len -= LOWMSG_BCAST_LEN;
  }
#endif 

  // printf("dispatch: 0x%02x\n", *buf);

  if (len > 0 && ((*buf) >> 3) == LOWPAN_FRAG1_PATTERN) {
    headers |= LOWMSG_FRAG1_HDR;
    buf += LOWMSG_FRAG1_LEN;
    len -= LOWMSG_FRAG1_LEN;
  }
  if (len > 0 && ((*buf) >> 3) == LOWPAN_FRAGN_PATTERN) {
    headers |= LOWMSG_FRAGN_HDR;
    buf += LOWMSG_FRAGN_LEN;
    len -= LOWMSG_FRAGN_LEN;
  }
  return headers;
}

/*
 * Fill in dispatch values
 */
inline uint8_t setupHeaders(struct packed_lowmsg *packed, uint16_t headers) {
  uint8_t *buf = packed->data;
  uint16_t len = packed->len;
  if (packed == NULL) return 1;
  if (buf == NULL) return 1;
  packed->headers = 0;
#if LIB6LOWPAN_FULL
  if (headers & LOWMSG_MESH_HDR)  {
    if (len < LOWMSG_MESH_LEN) return 1;
    packed->headers |= LOWMSG_MESH_HDR;
    *buf = LOWPAN_MESH_PATTERN << 6 | LOWPAN_MESH_V_MASK | LOWPAN_MESH_F_MASK;
    buf += LOWMSG_MESH_LEN;
    len -= LOWMSG_MESH_LEN;
  }
  if (headers & LOWMSG_BCAST_HDR) {
    if (len < LOWMSG_BCAST_LEN) return 1;
    packed->headers |= LOWMSG_BCAST_HDR;
    *buf = LOWPAN_BCAST_PATTERN;
    buf += LOWMSG_BCAST_LEN;
    len -= LOWMSG_BCAST_LEN;
  }
#endif
  if (headers & LOWMSG_FRAG1_HDR) {
    if (len < LOWMSG_FRAG1_LEN) return 1;
    packed->headers |= LOWMSG_FRAG1_HDR;
    *buf = LOWPAN_FRAG1_PATTERN << 3;
    buf += LOWMSG_FRAG1_LEN;
    len -= LOWMSG_FRAG1_LEN;
  }
  if (headers & LOWMSG_FRAGN_HDR) {
    if (len < LOWMSG_FRAGN_LEN) return 1;
    packed->headers |= LOWMSG_FRAGN_HDR;
    *buf = LOWPAN_FRAGN_PATTERN << 3;
  }
  return 0;
  
}

/*
 * Test if various headers are present are enabled
 */
#ifdef LIB6LOWPAN_FULL
inline uint8_t hasMeshHeader(struct packed_lowmsg *msg) {
  return (msg->headers & LOWMSG_MESH_HDR);
}
inline uint8_t hasBcastHeader(struct packed_lowmsg *msg) {
  return (msg->headers & LOWMSG_BCAST_HDR);
}
#endif
inline uint8_t hasFrag1Header(struct packed_lowmsg *msg) {
  return (msg->headers & LOWMSG_FRAG1_HDR);
}
inline uint8_t hasFragNHeader(struct packed_lowmsg *msg) {
  return (msg->headers & LOWMSG_FRAGN_HDR);
}
#ifdef LIB6LOWPAN_FULL
/*
 * Mesh header fields
 *
 *  return FAIL if the message doesn't have a mesh header
 */
inline uint8_t getMeshHopsLeft(struct packed_lowmsg *msg, uint8_t *hops) {
  uint8_t *buf = msg->data;
  if (!hasMeshHeader(msg) || msg->data == NULL || hops == NULL) return 1;
  *hops = (*buf) & LOWPAN_MESH_HOPS_MASK;
  return 0;
}
inline uint8_t getMeshOriginAddr(struct packed_lowmsg *msg, ieee154_saddr_t *origin) {
  uint8_t *buf = msg->data;
  if (!hasMeshHeader(msg) || msg->data == NULL || origin == NULL) return 1;
  // skip 64-bit addresses
  if (!(*buf & LOWPAN_MESH_V_MASK)) return 1;
  buf += 1;
  *origin = ntohs(*((uint16_t *)buf));
  return 0;
}
inline uint8_t getMeshFinalAddr(struct packed_lowmsg *msg, ieee154_saddr_t *final) {
  uint8_t *buf = msg->data;
  if (!hasMeshHeader(msg) || msg->data == NULL || final == NULL) return 1;
  // skip 64-bit addresses
  if (!(*buf & LOWPAN_MESH_F_MASK)) return 1;
  buf += 3;
  *final = ntohs(*((uint16_t *)buf));
  return 0;
}


inline uint8_t setMeshHopsLeft(struct packed_lowmsg *msg, uint8_t hops) {
  uint8_t *buf = msg->data;
  if (!hasMeshHeader(msg) || msg->data == NULL) return 1;
  
  *buf = 0xb0;
  *buf |= hops & LOWPAN_MESH_HOPS_MASK;
  return 0;
}
inline uint8_t setMeshOriginAddr(struct packed_lowmsg *msg, ieee154_saddr_t origin) {
  uint8_t *buf = msg->data;
  if (!hasMeshHeader(msg) || msg->data == NULL) return 1;
  // skip 64-bit addresses
  if (!(*buf & LOWPAN_MESH_V_MASK)) return 1;
  buf += 1;
  *((uint16_t *)buf) = htons(origin);
  return 0;
}
inline uint8_t setMeshFinalAddr(struct packed_lowmsg *msg, ieee154_saddr_t final) {
  uint8_t *buf = msg->data;
  if (!hasMeshHeader(msg) || msg->data == NULL) return 1;
  // skip 64-bit addresses
  if (!(*buf & LOWPAN_MESH_F_MASK)) return 1;
  buf += 3;
  *((uint16_t *)buf) = htons(final);
  return 0;
}
 
/*
 * Broadcast header fields
 */
inline uint8_t getBcastSeqno(struct packed_lowmsg *msg, uint8_t *seqno) {
  uint8_t *buf = msg->data;
  if (buf == NULL || seqno == NULL || !hasBcastHeader(msg)) return 1;
  if (hasMeshHeader(msg)) buf += LOWMSG_MESH_LEN;
  if (*buf != LOWPAN_BCAST_PATTERN) return 2;
  buf += 1;
  *seqno = *buf;
  return 0;
}

inline uint8_t setBcastSeqno(struct packed_lowmsg *msg, uint8_t seqno) {
  uint8_t *buf = msg->data;
  if (buf == NULL || !hasBcastHeader(msg)) return 1;
  if (hasMeshHeader(msg)) buf += LOWMSG_MESH_LEN;
  if (*buf != LOWPAN_BCAST_PATTERN) return 2;
  buf += 1;
  *buf = seqno;
  return 0;
}
#endif

/*
 * Fragmentation header fields
 */
inline uint8_t getFragDgramSize(struct packed_lowmsg *msg, uint16_t *size) {
  uint8_t *buf = msg->data;
  uint8_t s[2];
  if (buf == NULL || size == NULL) return 1;
#ifdef LIB6LOWPAN_FULL
  if (hasMeshHeader(msg)) buf += LOWMSG_MESH_LEN;
  if (hasBcastHeader(msg)) buf += LOWMSG_BCAST_LEN;
#endif
  if ((*buf >> 3) != LOWPAN_FRAG1_PATTERN &&
      (*buf >> 3) != LOWPAN_FRAGN_PATTERN) return 1;

  s[0] = *buf & 0x7;
  buf++;
  s[1] = *buf;
  *size = ((uint16_t)s[0]) << 8 | s[1];
  return 0;
}
inline uint8_t getFragDgramTag(struct packed_lowmsg *msg, uint16_t *tag) {
  uint8_t *buf = msg->data;
  if (buf == NULL || tag == NULL) return 1;
#ifdef LIB6LOWPAN_FULL
  if (hasMeshHeader(msg)) buf += LOWMSG_MESH_LEN;
  if (hasBcastHeader(msg)) buf += LOWMSG_BCAST_LEN;
#endif
  if ((*buf >> 3) != LOWPAN_FRAG1_PATTERN &&
      (*buf >> 3) != LOWPAN_FRAGN_PATTERN) return 1;
  buf += 2;
  //*tag = (*buf << 8) | *(buf + 1);  ;
  *tag = ntohs( *(uint16_t *)buf);
  return 0;
}
inline uint8_t getFragDgramOffset(struct packed_lowmsg *msg, uint8_t *size) {
  uint8_t *buf = msg->data;
  if (buf == NULL || size == NULL) return 1;
#ifdef LIB6LOWPAN_FULL
  if (hasMeshHeader(msg)) buf += LOWMSG_MESH_LEN;
  if (hasBcastHeader(msg)) buf += LOWMSG_BCAST_LEN;
#endif
  if ((*buf >> 3) != LOWPAN_FRAGN_PATTERN) return 1;
  buf += 4;
  *size = *buf;
  return 0;

}


inline uint8_t setFragDgramSize(struct packed_lowmsg *msg, uint16_t size) {
  uint8_t *buf = msg->data;
  if (buf == NULL) return 1;
#ifdef LIB6LOWPAN_FULL
  if (hasMeshHeader(msg)) buf += LOWMSG_MESH_LEN;
  if (hasBcastHeader(msg)) buf += LOWMSG_BCAST_LEN;
#endif
  if ((*buf >> 3) != LOWPAN_FRAG1_PATTERN &&
      (*buf >> 3) != LOWPAN_FRAGN_PATTERN) return 1;
  size = size & 0x7ff;

  // zero out the dgram size first.
  *buf &= 0xf8;
  *buf  |= (size >> 8);
  buf[1] = size & 0xff;

  // *((uint16_t *)buf) |= htons(size & 0x7ff);
  return 0;
}

inline uint8_t setFragDgramTag(struct packed_lowmsg *msg, uint16_t tag) {
  uint8_t *buf = msg->data;
  if (buf == NULL) return 1;
#ifdef LIB6LOWPAN_FULL
  if (hasMeshHeader(msg)) buf += LOWMSG_MESH_LEN;
  if (hasBcastHeader(msg)) buf += LOWMSG_BCAST_LEN;
#endif
  
  if ((*buf >> 3) != LOWPAN_FRAG1_PATTERN &&
      (*buf >> 3) != LOWPAN_FRAGN_PATTERN) return 1;
  buf += 2;

  buf[0] = tag >> 8;
  buf[1] = tag & 0xff;
  return 0;
}
inline uint8_t setFragDgramOffset(struct packed_lowmsg *msg, uint8_t size) {
  uint8_t *buf = msg->data;
  if (buf == NULL) return 1;
#ifdef LIB6LOWPAN_FULL
  if (hasMeshHeader(msg)) buf += LOWMSG_MESH_LEN;
  if (hasBcastHeader(msg)) buf += LOWMSG_BCAST_LEN;
#endif

  if ((*buf >> 3) != LOWPAN_FRAGN_PATTERN) return 1;
  buf += 4;
  *buf = size;
  return 0;
}
