#ifndef TDA5250_MESSAGE_H
#define TDA5250_MESSAGE_H

#include "AM.h"
#include "PacketAck.h"

typedef nx_struct tda5250_header_t {
  nx_uint8_t   length;
  nx_am_addr_t src;
  nx_am_addr_t dest;
  nx_am_id_t   type;
  nx_am_group_t group;
  nx_uint8_t   token;
} tda5250_header_t;

typedef nx_struct tda5250_footer_t {
  nxle_uint16_t crc;
} tda5250_footer_t;

typedef nx_struct tda5250_metadata_t {
  nx_uint16_t strength;
  nx_uint8_t ack;
  /* local time when message was generated */
  nx_uint32_t time;
  nx_uint8_t sendSecurityMode;
  nx_uint8_t receiveSecurityMode;
} tda5250_metadata_t;

#endif
