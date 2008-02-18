/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#include "routing_table.h"

/**
 * DymoTable - Interface to manipulate a dymo routing table
 *
 * @author Romain Thouvenin
 */

interface DymoTable {

  /**
   * Update the table with fresh information about a destination.
   * @param route_info The routing information associated to the destination
   * @param msg_type The type of message that provided this info
   * @return SUCCESS if the route was added or updated<br/>
   *         EINVAL  if route_info was inferior to existing route, 
   *                 or msg_type = rerr and the route does not exist
   *         FAIL    if the table was full and no existing route could be deleted<br/>
   */
  command error_t update(const rt_info_t * route_info, dymo_msg_t msg_type);

  command bool isSuperior(const rt_info_t * route_info, dymo_msg_t msg_type);

  /**
   * Signal that a component asked for an unknown route, a RREQ should
   * be generated.
   * @param destination Target node of the needed route.
   */
  event void routeNeeded(addr_t destination);

  event void brokenRouteNeeded(const rt_info_t * route_info);
}
