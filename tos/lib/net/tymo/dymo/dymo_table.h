/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#ifndef _DYMO_TABLE_H_
#define _DYMO_TABLE_H_

#include "routing_table.h"

/**
 * Types associated to a dymo routing table.
 * @author Romain Thouvenin
 */

typedef struct rt_entry {
  rt_info_t info;
  uint8_t flags;
} rt_entry_t;

typedef enum {
  FLAG_BROKEN = 0x01,
  FLAG_NEW = 0x02,
  FLAG_USED = 0x04,
  FLAG_DELETED = 0x08,
} rt_flag_t;

typedef enum { //TODO optimize the number of timers
  ROUTE_AGE_MIN = 0,
  ROUTE_AGE_MAX,
  ROUTE_NEW,
  ROUTE_USED,
  ROUTE_DELETE,
  NB_ROUTE_TIMERS
} rt_timer_t;

uint32_t timer_values[NB_ROUTE_TIMERS] = {
  1000,                //ROUTE_AGE_MIN
  DYMO_ROUTE_AGE_MAX,  //ROUTE_AGE_MAX
  DYMO_ROUTE_TIMEOUT,   //ROUTE_NEW
  DYMO_ROUTE_TIMEOUT,   //ROUTE_USED
  DYMO_ROUTE_TIMEOUT * 2   //ROUTE_DELETE
};


#endif
