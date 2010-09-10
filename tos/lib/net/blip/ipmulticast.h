#ifndef IPMULTICAST_H_
#define IPMULTICAST_H_

#include <ip.h>

enum {
  MCAST_FW_MAXLEN = 50,
};

struct mcast_hdr {
  struct tlv_hdr tlv;
  uint16_t mcast_seqno;
};

#endif
