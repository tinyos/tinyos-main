#ifndef _NWBYTE_H
#define _NWBYTE_H_

#if !defined(PC)
// if we're not on a pc, assume little endian for now
#define __LITTLE_ENDIAN 1234
#define __BYTE_ORDER __LITTLE_ENDIAN
#endif

/* define normal network byte-orders routines  */
#if defined(PC) 
// use library versions if on linux
#include <stdlib.h>
#else
#if __BYTE_ORDER == __LITTLE_ENDIAN
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


#else 
#error "No byte-order conversions defined!"
#endif
#endif

/* little-endian conversion routines */

#if __BYTE_ORDER == __LITTLE_ENDIAN
#define leton16(X)  htons(X)
#ifndef htole16
#define htole16(X)  (X)
#endif
#define letohs(X) (X)

#else
// assume big-endian byte-order
#define leton16(X) (((((uint16_t)(X)) << 8) | ((uint16_t)(X) >> 8)) & 0xffff)
#define htole16(X) (((((uint16_t)(X)) << 8) | ((uint16_t)(X) >> 8)) & 0xffff)


#endif

#endif
