#ifndef TDA5250_MESSAGE_H
#define TDA5250_MESSAGE_H

#include "AM.h"
#include "PacketAck.h"

/*
 * highest bit of token set: this message is ACK and not intended for the
 * upper layers. Token is used for alternating bit like duplicate detection,
 * and set by the sender in [0,127] intervall. The receiver reflects the
 * token in the Ack, with the highest bit set. 
 */

typedef nx_struct tda5250_header_t {
  nx_uint8_t    length;
  nx_am_addr_t  src;
  nx_am_addr_t  dest;
  nx_am_id_t    type;
  nx_uint8_t    token;
} tda5250_header_t;

typedef nx_struct tda5250_footer_t {
  nxle_uint16_t crc;
} tda5250_footer_t;

typedef nx_struct tda5250_metadata_t {
  nx_uint16_t strength;
  nx_uint8_t ack;
  /* local time when message was generated */
  nx_uint32_t time;
  /* time of sfd generation */
  nx_uint32_t sfdtime;
  nx_uint8_t sendSecurityMode;
  nx_uint8_t receiveSecurityMode;
  /* some meta information that allows to compute a density */
  nx_uint8_t maxRepetitions;
  nx_uint8_t repetitions;
} tda5250_metadata_t;

#endif
