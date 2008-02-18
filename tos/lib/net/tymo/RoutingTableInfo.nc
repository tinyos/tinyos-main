/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#include "routing_table.h"

typedef nx_struct rt_link {
  nx_addr_t target;
  nx_addr_t nexthop;
} rt_link_t;

interface RoutingTableInfo {

  /**
   * Size of the table.
   * @return the number of entries stored in the table
   */
  command uint8_t size();

  command uint8_t maxSize();

  command uint8_t getTableContent(rt_info_t * buf);

  command uint8_t getLinks(rt_link_t * buf);

}
