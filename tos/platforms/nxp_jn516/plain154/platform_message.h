#ifndef PLATFORM_MESSAGE_H
#define PLATFORM_MESSAGE_H

#include <Serial.h>

/* The following include pulls in the plain154_header_t/plain154_metadata_t definitions */
#include <plain154_message_structs.h>

/* TOSH_DATA_LENGTH should be the maximum length of the MAC payload */
/*
// biggest payload possible with an ACK with 1 byte FCF and 2 bytes FCS in 15.4e Frame Version 0b10
#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 124
#elif TOSH_DATA_LENGTH < 124
#warning "MAC payload region is smaller than aMaxMACPayloadSize!"
#endif
*/

typedef union message_header {
  plain154_header_t plain154;
  serial_header_t serial;
} message_header_t;

typedef union TOSRadioFooter {
} message_footer_t;

typedef union TOSRadioMetadata {
  plain154_metadata_t plain154;
} message_metadata_t;

#endif
