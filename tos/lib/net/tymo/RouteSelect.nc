/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#include "routing.h"

/**
 * Interface to a route selection in a multi-hop context.
 *
 * @author Romain Thouvenin
 */

interface RouteSelect {

  /**
   * Ask the routing engine to fill a message with routing
   * information, in order to send it to its target.
   *
   * @param msg The message to be sent
   * @param destination The target of the route. If NULL, it is assumed it can be read in the packet
   * @return The action that should be taken by the forwarding engine.
   */
  command fw_action_t selectRoute(message_t * msg, addr_t * destination, uint8_t * am_type);
  
}
