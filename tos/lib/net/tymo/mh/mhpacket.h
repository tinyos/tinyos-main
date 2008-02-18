#ifndef MHPACKET_H
#define MHPACKET_H

#include "AM.h"
#include "message.h"
#include "routing.h"

typedef nx_struct mhpacket_header {
  nx_uint8_t len;
  nx_uint8_t type;
  nx_am_addr_t src;
  nx_am_addr_t dest;
} mhpacket_header_t;

typedef nx_struct mhpacket {
  mhpacket_header_t header;
  nx_uint8_t data[];
} mhpacket_t;

enum { //for mig
  AM_MHPACKET = AM_MULTIHOP,
};

#endif
