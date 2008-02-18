/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#ifndef _ROUTING_TABLE_H_
#define _ROUTING_TABLE_H_

#include "routing.h"

/**
 * Types associated to a routing table.
 */

typedef struct rt_info {
  addr_t address;
  addr_t nexthop;
  seqnum_t seqnum;
  bool has_hopcnt;
  uint8_t hopcnt;
} rt_info_t;

typedef enum {
  REASON_FULL,
  REASON_OLD,
  REASON_UNREACHABLE
} reason_t;

#endif
