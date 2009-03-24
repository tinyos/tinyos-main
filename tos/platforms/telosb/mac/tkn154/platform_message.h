


#ifndef PLATFORM_MESSAGE_H
#define PLATFORM_MESSAGE_H

#include <Serial.h>

#ifndef IEEE154_OLD_INTERFACES
#include <TKN154_MAC.h>
#else
typedef struct {
  uint8_t control;  // stores length (lower 7 bits), top bit -> promiscuous mode
  uint8_t mhr[MHR_MAX_LEN];  // maximum header size without security
} ieee154_header_t;

typedef struct {
  uint8_t rssi;
  uint8_t linkQuality;
  uint32_t timestamp;
} ieee154_metadata_t;
#endif

//#ifdef TOSH_DATA_LENGTH
//#undef TOSH_DATA_LENGTH
//#endif
// TOSH_DATA_LENGTH may be smaller than 118, but then we'll
// not be able to receive/send all IEEE 802.15.4 packets 
#define TOSH_DATA_LENGTH 118

typedef union message_header {
  ieee154_header_t ieee154;
  serial_header_t serial;
} message_header_t;

typedef union TOSRadioFooter {
} message_footer_t;

typedef union TOSRadioMetadata {
  ieee154_metadata_t ieee154;
} message_metadata_t;

#endif
