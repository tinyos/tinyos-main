#ifndef TDA5250_MESSAGE_H
#define TDA5250_MESSAGE_H

#include "AM.h"

typedef nx_struct tda5250_header_t {
  nx_am_addr_t addr;
  nx_uint8_t length;
  nx_am_group_t group;
  nx_am_id_t type;
} tda5250_header_t;

typedef nx_struct tda5250_footer_t {
  nxle_uint16_t crc;
} tda5250_footer_t;

typedef nx_struct tda5250_metadata_t {
  nx_uint16_t strength;
  nx_uint8_t ack;
  nx_uint16_t time;
  nx_uint8_t sendSecurityMode;
  nx_uint8_t receiveSecurityMode;
} tda5250_metadata_t;

#endif
