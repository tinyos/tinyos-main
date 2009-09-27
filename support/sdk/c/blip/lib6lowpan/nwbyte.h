#ifndef _NWBYTE_H
#define _NWBYTE_H_

#include "blip-platform.h"

/* define normal network byte-orders routines  */
#if defined(PC) 

#define ntoh16(X)   ntohs(X)
#define hton16(X)   htons(X)
#define ntoh32(X)   ntohl(X)
#define hton32(X)   htonl(X)
#else
#if __BYTE_ORDER == __LITTLE_ENDIAN
// otherwise have to provide our own 

#define ntoh16(X)   (((((uint16_t)(X)) >> 8) | ((uint16_t)(X) << 8)) & 0xffff)
#define hton16(X)   (((((uint16_t)(X)) << 8) | ((uint16_t)(X) >> 8)) & 0xffff)

/* this is much more efficient since gcc can insert swpb now.  */
static inline uint32_t __attribute__((unused))  ntoh32(uint32_t i) {
  uint16_t lo = (uint16_t)i;
  uint16_t hi = (uint16_t)(i >> 16);
  lo = (lo << 8) | (lo >> 8);
  hi = (hi << 8) | (hi >> 8);
  return (((uint32_t)lo) << 16) | ((uint32_t)hi);
}

#define hton32(X) ntoh32(X)
#define ntohs(X) ntoh16(X)
#define htons(X) hton16(X)
#define ntohl(X) ntoh32(X)
#define htonl(X) hton32(X)

#else 
#error "No byte-order conversions defined!"
#endif
#endif

/* little-endian conversion routines */

#if __BYTE_ORDER == __LITTLE_ENDIAN
#define leton16(X)  hton16(X)
#ifndef htole16
#define htole16(X)  (X)
#endif

#else
//  big-endian byte-order
#define leton16(X) (((((uint16_t)(X)) << 8) | ((uint16_t)(X) >> 8)) & 0xffff)
#define htole16(X) (((((uint16_t)(X)) << 8) | ((uint16_t)(X) >> 8)) & 0xffff)
#endif

#endif
