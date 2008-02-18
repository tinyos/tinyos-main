/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#include "routing.h"

/**
 * MHEngineM - Implements a simple transport protocol, which is
 * nothing more than AM on top of the existing AM stack.
 *
 * @author Romain Thouvenin
 */
module MHEngineM {
  provides interface RouteSelect;
  uses {
    interface AMPacket as MHPacket;
    interface AMPacket;
    interface RoutingTable;
  }
}

implementation {

  rt_info_t info;

  command fw_action_t RouteSelect.selectRoute(message_t * msg, addr_t * destination, uint8_t * am_type){
    dbg("mhe", "MHE: Somebody wants a route, let's see...\n");
    if( call MHPacket.isForMe(msg) 
	|| (destination && (*destination == call MHPacket.address())) ){
      
      *am_type = call MHPacket.type(msg);
      return FW_RECEIVE;

    } else {
      
      error_t e;
      if(destination)
	e = call RoutingTable.getRoute(*destination, &info);
      else
	e = call RoutingTable.getForwardingRoute(call MHPacket.destination(msg), &info);

      if(e == SUCCESS){

	dbg("mhe", "MHE: I've selected a route to %u through %u.\n", info.address, info.nexthop);
	call AMPacket.setDestination(msg, info.nexthop);

	if(destination){
	  call MHPacket.setType(msg, *am_type);
	  call MHPacket.setDestination(msg, *destination);
	  call MHPacket.setSource(msg, call MHPacket.address());
	} else {
	  *am_type = call MHPacket.type(msg);
	}
	return FW_SEND;

      } else if(e == EBUSY){
	dbg("mhe", "MHE: No route is available for now.\n");
	return FW_WAIT;
      } else {
	dbg("mhe", "MHE: I'm discarding the message.\n");
	return FW_DISCARD;
      }

    }
  }

  event void RoutingTable.evicted(const rt_info_t * rt_info, reason_t r){}

}
