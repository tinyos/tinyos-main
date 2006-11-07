#ifndef CC1K_RADIO_MSG_H
#define CC1K_RADIO_MSG_H

#include "AM.h"

typedef nx_struct CC1KHeader {
  nx_am_addr_t dest;
  nx_am_addr_t source;
  nx_uint8_t length;
  nx_am_group_t group;
  nx_am_id_t type;
} cc1000_header_t;

typedef nx_struct CC1KFooter {
  nxle_uint16_t crc;  
} cc1000_footer_t;

typedef nx_struct CC1KMetadata {
  nx_int16_t strength_or_preamble; /* negative when used for preamble length */
  nx_uint8_t ack;
  nx_uint16_t time;
  nx_uint8_t sendSecurityMode;
  nx_uint8_t receiveSecurityMode;  
} cc1000_metadata_t;

#endif
