/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#include "routing_table.h"

/**
 * RoutingTable - Interface to manipulate a data structure that stores
 * a table of routes toward a number of destinations.
 *
 * @author Romain Thouvenin
 */

interface RoutingTable {

  /**
   * Request for a route toward a destination.
   * @param Address of the destination node
   * @param info A pointer where to store the routing information 
   *        associated to the destination, ignored if NULL
   * @return SUCCESS if the route exists<br/>
   *         EBUSY if the route does not exist but may be available soon
   *         FAIL  if the route exists but is broken
   */
  command error_t getRoute(addr_t address, rt_info_t * info);

  command error_t getForwardingRoute(addr_t address, rt_info_t * info);

  /**
   * Signal that a route has been removed from the table.
   * @param route_info Routing information associated to the evicted entry
   * @param r reason of the eviction
   */
  event void evicted(const rt_info_t * route_info, reason_t r);

}
