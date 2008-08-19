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

typedef enum {
  CC1000_ACK_BIT   = 0x1,
  CC1000_WHITE_BIT = 0x2,
  /* 60 comes from the mica2 data sheet (MPR/MIB guide) and Dongjin Son's work in SenSys 2006.
     Son's work showed that a SINR of 6dB is sufficient for > 90% PRR. Figure 7-2 of the data
     sheet shows that a 6dB difference is approximately equal to a VRSSI voltage difference of
     0.15V. Since the battery voltage is 2.8V (approximately), 60/1024 * 2.8 is roughly equal
     to 0.15. This deserves some experimental testing. -pal */
  CC1000_WHITE_BIT_THRESH = 60
} CC1KMetadataBits;

typedef nx_struct CC1KMetadata {
  nx_int16_t strength_or_preamble; /* negative when used for preamble length */
  nx_uint8_t metadataBits;
  nx_bool timesync;
  nx_uint32_t timestamp;
  nx_uint8_t sendSecurityMode;
  nx_uint8_t receiveSecurityMode;  
} cc1000_metadata_t;

enum
{
  CC1000_INVALID_TIMESTAMP  = 0x80000000L,
};

#endif
