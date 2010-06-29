/*
 * Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
#include "6lowpan.h"
#include "ip.h"
#include "lib6lowpan.h"


#ifndef __6LOWPAN_16BIT_ADDRESS
#error "Only 16-bit short addresses are supported"
#endif

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
inline uint8_t *getLowpanPayload(packed_lowmsg_t *lowmsg) {
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
inline uint16_t getHeaderBitmap(packed_lowmsg_t *lowmsg) {
  uint16_t headers = 0;
  uint8_t *buf = lowmsg->data;
  uint16_t len = lowmsg->len;
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
inline uint8_t setupHeaders(packed_lowmsg_t *packed, uint16_t headers) {
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
    if (len < LOWMSG_FRAG1_HDR) return 1;
    packed->headers |= LOWMSG_FRAG1_HDR;
    *buf = LOWPAN_FRAG1_PATTERN << 3;
    buf += LOWMSG_FRAG1_LEN;
    len -= LOWMSG_FRAG1_LEN;
  }
  if (headers & LOWMSG_FRAGN_HDR) {
    if (len < LOWMSG_FRAGN_HDR) return 1;
    packed->headers |= LOWMSG_FRAGN_HDR;
    *buf = LOWPAN_FRAGN_PATTERN << 3;
  }
  return 0;
  
}

/*
 * Test if various headers are present are enabled
 */
#ifdef LIB6LOWPAN_FULL
inline uint8_t hasMeshHeader(packed_lowmsg_t *msg) {
  return (msg->headers & LOWMSG_MESH_HDR);
}
inline uint8_t hasBcastHeader(packed_lowmsg_t *msg) {
  return (msg->headers & LOWMSG_BCAST_HDR);
}
#endif
inline uint8_t hasFrag1Header(packed_lowmsg_t *msg) {
  return (msg->headers & LOWMSG_FRAG1_HDR);
}
inline uint8_t hasFragNHeader(packed_lowmsg_t *msg) {
  return (msg->headers & LOWMSG_FRAGN_HDR);
}
#ifdef LIB6LOWPAN_FULL
/*
 * Mesh header fields
 *
 *  return FAIL if the message doesn't have a mesh header
 */
inline uint8_t getMeshHopsLeft(packed_lowmsg_t *msg, uint8_t *hops) {
  uint8_t *buf = msg->data;
  if (!hasMeshHeader(msg) || msg->data == NULL || hops == NULL) return 1;
  *hops = (*buf) & LOWPAN_MESH_HOPS_MASK;
  return 0;
}
inline uint8_t getMeshOriginAddr(packed_lowmsg_t *msg, ieee154_saddr_t *origin) {
  uint8_t *buf = msg->data;
  if (!hasMeshHeader(msg) || msg->data == NULL || origin == NULL) return 1;
  // skip 64-bit addresses
  if (!(*buf & LOWPAN_MESH_V_MASK)) return 1;
  buf += 1;
  *origin = ntoh16(*((uint16_t *)buf));
  return 0;
}
inline uint8_t getMeshFinalAddr(packed_lowmsg_t *msg, ieee154_saddr_t *final) {
  uint8_t *buf = msg->data;
  if (!hasMeshHeader(msg) || msg->data == NULL || final == NULL) return 1;
  // skip 64-bit addresses
  if (!(*buf & LOWPAN_MESH_F_MASK)) return 1;
  buf += 3;
  *final = ntoh16(*((uint16_t *)buf));
  return 0;
}


inline uint8_t setMeshHopsLeft(packed_lowmsg_t *msg, uint8_t hops) {
  uint8_t *buf = msg->data;
  if (!hasMeshHeader(msg) || msg->data == NULL) return 1;
  
  *buf = 0xb0;
  *buf |= hops & LOWPAN_MESH_HOPS_MASK;
  return 0;
}
inline uint8_t setMeshOriginAddr(packed_lowmsg_t *msg, ieee154_saddr_t origin) {
  uint8_t *buf = msg->data;
  if (!hasMeshHeader(msg) || msg->data == NULL) return 1;
  // skip 64-bit addresses
  if (!(*buf & LOWPAN_MESH_V_MASK)) return 1;
  buf += 1;
  *((uint16_t *)buf) = hton16(origin);
  return 0;
}
inline uint8_t setMeshFinalAddr(packed_lowmsg_t *msg, ieee154_saddr_t final) {
  uint8_t *buf = msg->data;
  if (!hasMeshHeader(msg) || msg->data == NULL) return 1;
  // skip 64-bit addresses
  if (!(*buf & LOWPAN_MESH_F_MASK)) return 1;
  buf += 3;
  *((uint16_t *)buf) = hton16(final);
  return 0;
}
 
/*
 * Broadcast header fields
 */
inline uint8_t getBcastSeqno(packed_lowmsg_t *msg, uint8_t *seqno) {
  uint8_t *buf = msg->data;
  if (buf == NULL || seqno == NULL || !hasBcastHeader(msg)) return 1;
  if (hasMeshHeader(msg)) buf += LOWMSG_MESH_LEN;
  if (*buf != LOWPAN_BCAST_PATTERN) return 2;
  buf += 1;
  *seqno = *buf;
  return 0;
}

inline uint8_t setBcastSeqno(packed_lowmsg_t *msg, uint8_t seqno) {
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
inline uint8_t getFragDgramSize(packed_lowmsg_t *msg, uint16_t *size) {
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
  *size = ntoh16 ( *(uint16_t *)s);
  return 0;
}
inline uint8_t getFragDgramTag(packed_lowmsg_t *msg, uint16_t *tag) {
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
  *tag = ntoh16( *(uint16_t *)buf);
  return 0;
}
inline uint8_t getFragDgramOffset(packed_lowmsg_t *msg, uint8_t *size) {
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


inline uint8_t setFragDgramSize(packed_lowmsg_t *msg, uint16_t size) {
  uint8_t *buf = msg->data;
  if (buf == NULL) return 1;
#ifdef LIB6LOWPAN_FULL
  if (hasMeshHeader(msg)) buf += LOWMSG_MESH_LEN;
  if (hasBcastHeader(msg)) buf += LOWMSG_BCAST_LEN;
#endif
  if ((*buf >> 3) != LOWPAN_FRAG1_PATTERN &&
      (*buf >> 3) != LOWPAN_FRAGN_PATTERN) return 1;
  // zero out the dgram size first.
  *buf &= 0xf8;
  *(buf + 1) = 0;
  *((uint16_t *)buf) |= hton16(size & 0x7ff);
  return 0;
}

inline uint8_t setFragDgramTag(packed_lowmsg_t *msg, uint16_t tag) {
  uint8_t *buf = msg->data;
  if (buf == NULL) return 1;
#ifdef LIB6LOWPAN_FULL
  if (hasMeshHeader(msg)) buf += LOWMSG_MESH_LEN;
  if (hasBcastHeader(msg)) buf += LOWMSG_BCAST_LEN;
#endif
  
  if ((*buf >> 3) != LOWPAN_FRAG1_PATTERN &&
      (*buf >> 3) != LOWPAN_FRAGN_PATTERN) return 1;
  buf += 2;
  *(uint16_t *)buf = ntoh16(tag);
  return 0;
}
inline uint8_t setFragDgramOffset(packed_lowmsg_t *msg, uint8_t size) {
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
