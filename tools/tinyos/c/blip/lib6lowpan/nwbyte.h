#ifndef _NWBYTE_H
#define _NWBYTE_H

#if !defined(PC)
#ifndef TOS_LITTLE_ENDIAN
#define TOS_LITTLE_ENDIAN 1234
#endif
#ifndef TOS_BIG_ENDIAN
#define TOS_BIG_ENDIAN 4321
#endif
#ifndef TOS_BYTE_ORDER
#define TOS_BYTE_ORDER TOS_LITTLE_ENDIAN
#endif
#endif

/* define normal network byte-orders routines  */
#if defined(PC) 
// use library versions if on linux
#include <stdlib.h>
#else
#if TOS_BYTE_ORDER == TOS_LITTLE_ENDIAN
// otherwise have to provide our own 

#ifndef WITH_OSHAN
#define ntohs(X)   (((((uint16_t)(X)) >> 8) | ((uint16_t)(X) << 8)) & 0xffff)
#define htons(X)   (((((uint16_t)(X)) << 8) | ((uint16_t)(X) >> 8)) & 0xffff)

/* this is much more efficient since gcc can insert swpb now.  */
/* moved to utility.c */
uint32_t ntohl(uint32_t i);
#define htonl(X) ntohl(X)
#else 
#include <arpa/inet.h>
#endif

#elif TOS_BYTE_ORDER == TOS_BIG_ENDIAN

#define ntohs(X) (X)
#define htons(X) (X)
#define htonl(X) (X)
#define ntohl(X) (X)

#else 
#error "No byte-order conversions defined!"
#endif
#endif

/* little-endian conversion routines */

#if TOS_BYTE_ORDER == TOS_LITTLE_ENDIAN
#define leton16(X)  htons(X)
#ifndef htole16
#define htole16(X)  (X)
#endif
#define letohs(X) (X)

#elif TOS_BYTE_ORDER == TOS_BIG_ENDIAN
// assume big-endian byte-order
#define leton16(X) (((((uint16_t)(X)) << 8) | ((uint16_t)(X) >> 8)) & 0xffff)
#define htole16(X) (((((uint16_t)(X)) << 8) | ((uint16_t)(X) >> 8)) & 0xffff)
#define letohs(X) (((((uint16_t)(X)) << 8) | ((uint16_t)(X) >> 8)) & 0xffff)

#else
#error "No byte-order conversions defined!"
#endif

#endif
