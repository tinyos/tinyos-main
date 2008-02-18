/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#ifndef _DYMO_ROUTING_H_
#define _DYMO_ROUTING_H_

#include "AM.h"

typedef am_addr_t addr_t;
typedef nx_am_addr_t nx_addr_t;
typedef uint16_t seqnum_t;
typedef nx_uint16_t nx_seqnum_t;

#ifndef MAX_TABLE_SIZE
#define MAX_TABLE_SIZE 5
#endif

#ifndef DYMO_HOPLIMIT
#define DYMO_HOPLIMIT 10
#endif

#ifndef DYMO_ROUTE_AGE_MAX
#define DYMO_ROUTE_AGE_MAX 300000
#endif

#ifndef DYMO_ROUTE_TIMEOUT
#define DYMO_ROUTE_TIMEOUT 10000
#endif

#ifndef DYMO_APPEND_INFO
#define DYMO_APPEND_INFO      0      //1 to append info to forwarded RMs
#endif

#ifndef DYMO_INTER_RREP
#define DYMO_INTER_RREP       1      //1 to allow intermediate RREP 
#endif

#ifndef DYMO_FORCE_INTER_RREP
#define DYMO_FORCE_INTER_RREP 1      //1 to send intermediate RREP even without target's seqnum in the RREQ
#endif

#ifndef DYMO_LINK_FEEDBACK
#define DYMO_LINK_FEEDBACK    1      //1 to use acks to detect broken links
#endif

enum {
  AM_MULTIHOP = 9,
  AM_DYMO = 8
};

typedef enum {
  DYMO_RREQ = 10,
  DYMO_RREP,
  DYMO_RERR
} dymo_msg_t;

//processing action
typedef enum {
  ACTION_KEEP,   //info is kept in the forwarded message
  //  ACTION_UPDATE, //info is kept, and updated with the provided info
  ACTION_DISCARD, //info is not kept in the forwarded message
  ACTION_DISCARD_MSG //The message won't be forwarded, no need to build a forwarded message anymore
} proc_action_t;

typedef enum {
  FW_SEND,      //Put the message in the sending queue
  FW_RECEIVE,   //Give the message to the upper layer
  FW_WAIT,      //Retry later
  FW_DISCARD,   //Discard the message
} fw_action_t;


#endif
