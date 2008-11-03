/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#include "dymo_table.h"

/**
 * DymoTableM - Implements a routing table with DYMO routing information.
 * @param maxsize maximum number of entries in the table, cannot be higher than 51
 *
 * @author Romain Thouvenin
 */

generic module DymoTableM(uint8_t maxsize) {
  provides {
    interface StdControl;
    interface RoutingTable;
    interface DymoTable;
  }
  uses {
    interface Timer<TMilli>[uint8_t id];
    interface LinkMonitor;
  }
#ifdef DYMO_MONITORING
  provides interface RoutingTableInfo;
#endif
}

implementation {

  rt_entry_t table[maxsize];
  rt_info_t buf_info;
  uint8_t size; 
  uint8_t num_entries;
  uint8_t replace;

  /* declared at the end */
  void replace_info(uint8_t entry_id, const rt_info_t * route_info);
  int8_t get_route(addr_t address);
  void delete_route(uint8_t entry_id, reason_t r);
  bool is_superior(const rt_info_t * info1, const rt_entry_t * entry, dymo_msg_t msg_type);
  void set_timer(uint8_t entry_id, rt_timer_t timer_id);
  void cancel_timer(uint8_t entry_id, rt_timer_t timer);
  void cancel_timers(uint8_t entry_id);

  command error_t StdControl.start(){
    num_entries = 0;
    size = 0;
    replace = 0;
    return SUCCESS;
  }

  command error_t StdControl.stop(){
    uint8_t i;
    for(i=0; i<num_entries; i++){
      if( !(table[i].flags & FLAG_DELETED) ){
	cancel_timers(i);
      }
    }
    return SUCCESS;
  }

  command error_t RoutingTable.getForwardingRoute(addr_t address, rt_info_t * info){
    int8_t i = get_route(address);
    dbg("dt", "DT: Someone wants a forwarding route for %u.\n", address);
    if(i == -1){
      dbg("dt", "DT: But I don't have it. => brokenRouteNeeded\n");
      buf_info.address = address;
      buf_info.seqnum = 0;
      buf_info.has_hopcnt = 0;
      signal DymoTable.brokenRouteNeeded(&buf_info);
      return FAIL;
    }

    //The caller may want to know what is in the table even if it is broken
    if(info && !(table[i].flags & FLAG_DELETED)){
      *info = table[i].info;
    }

    if(table[i].flags & (FLAG_BROKEN | FLAG_DELETED)){
      dbg("dt", "DT: But it is deleted. => brokenRouteNeeded\n");
      signal DymoTable.brokenRouteNeeded(&table[i].info); //TODO not if not used recently (for other signals too)
      return FAIL;
    }

    cancel_timer(i, ROUTE_NEW);
    table[i].flags &= ~FLAG_NEW;
    cancel_timer(i, ROUTE_DELETE);
    set_timer(i, ROUTE_USED);
    table[i].flags |= FLAG_USED;
    dbg("dt", "DT: Here it is: %u.\n", table[i].info.nexthop);
    return SUCCESS;
  }

  command error_t RoutingTable.getRoute(addr_t address, rt_info_t * info){
    int i = get_route(address);
    dbg("dt", "DT: Someone wants a sending route for %u.\n", address);
    if(i == -1){
      dbg("dt", "DT: But I don't have it. => routeNeeded\n");
      signal DymoTable.routeNeeded(address);
      return EBUSY;
    }

    //The caller may want to know what is in the table even if it is broken
    if(info){
      *info = table[i].info;
    }

    if(table[i].flags & (FLAG_DELETED | FLAG_BROKEN)){
      dbg("dt", "DT: But it is deleted or broken. => routeNeeded\n");
      signal DymoTable.routeNeeded(address);
      return EBUSY;
    }
    
    //We assume the route is going to be used
    cancel_timer(i, ROUTE_NEW);
    table[i].flags &= ~FLAG_NEW;
    cancel_timer(i, ROUTE_DELETE);
    set_timer(i, ROUTE_USED);
    table[i].flags |= FLAG_USED;
    dbg("dt", "DT: Here it is: %u-%u-%hhu.\n", table[i].info.nexthop, table[i].info.seqnum, table[i].info.hopcnt);
    return SUCCESS;
  }

  command error_t DymoTable.update(const rt_info_t * route_info, dymo_msg_t msg_type){
    int8_t i = get_route(route_info->address);

    if(msg_type == DYMO_RERR){

      if(i != -1){
	if( (table[i].info.nexthop == route_info->nexthop) 
	    && ((table[i].info.seqnum == 0)
		|| (route_info->seqnum == 0)
		|| (route_info->seqnum >= table[i].info.seqnum)) ){
	  table[i].flags |= FLAG_BROKEN;
	  dbg("dt", "DT: Route for %u evicted because of a RERR.\n", route_info->address);
	  signal RoutingTable.evicted(&table[i].info, REASON_UNREACHABLE);
	  return SUCCESS;
	} else {
	  return EINVAL;
	}
      } else {
	return EINVAL;
      }

    } else {

      if(i == -1){
	
	if(num_entries < maxsize){ //We have room to add a new route
	  
	  replace_info(num_entries, route_info);
	  num_entries++;
	  size++;
	  dbg("dt", "DT: Updated route for %u in entry %hhu.\n", route_info->address, num_entries-1); //TODO debug below too
	  return SUCCESS;

	} else { //We have to find a route to replace
	  //TODO possible optimization : caching the last deleted and broken route
	  int8_t j = -1; //will be set to a non-new route if found
	  
	  //We look for a deleted route
	  for(i=0; i<num_entries; i++){
	    if(table[i].flags & FLAG_DELETED){
	      replace_info(i, route_info);
	      return SUCCESS;
	    }
	  }

	  //the table is full, we try to replace an existing route
	  for(i=0; i<num_entries; i++){
	    if(table[i].flags & FLAG_BROKEN){
	      replace_info(i, route_info);
	      return SUCCESS;
	    } else if( !(table[i].flags & FLAG_NEW) ){
	      j = i;
	    }
	  }

	  //no broken route found, we a take a non-new route
	  //TODO rather take a non-used route
	  if(j != -1){
	    delete_route(j, REASON_FULL);
	    replace_info(j, route_info);
	    return SUCCESS;
	  }

	  /* No room found. We delete a random route */
	  delete_route(replace, REASON_FULL);
	  replace_info(replace++, route_info);
	  if (replace == maxsize)
	    replace = 0;
	  return SUCCESS;

	}

      } else { //if(i == -1)

	if(is_superior(route_info, table + i, msg_type)){
	  replace_info(i, route_info);
	  return SUCCESS;
	} else {
	  return EINVAL;
	}

      }

    }
  }

  command bool DymoTable.isSuperior(const rt_info_t * info, dymo_msg_t t){
    int8_t i = get_route(info->address);
    return ((i == -1) || is_superior(info, table + i, t));
  }

  event void Timer.fired[uint8_t timer_id](){
    uint8_t e = timer_id / NB_ROUTE_TIMERS;
    switch(timer_id % NB_ROUTE_TIMERS){
    case ROUTE_AGE_MIN:
      table[e].flags &= ~FLAG_NEW;
      break;
    case ROUTE_AGE_MAX:
      dbg("dt", "DT: Route for %u is really old, I delete it.\n", table[e].info.address);
      delete_route(e, REASON_OLD);
      break;
    case ROUTE_NEW:
      table[e].flags &= ~FLAG_NEW;
      set_timer(e, ROUTE_DELETE);
      break;
    case ROUTE_USED:
      table[e].flags &= ~FLAG_USED;
      set_timer(e, ROUTE_DELETE);
      break;
    case ROUTE_DELETE:
      dbg("dt", "DT: Route for %u is unused, I delete it.\n", table[e].info.address);
      delete_route(e, REASON_OLD);
      break;
    }
  }

  event void LinkMonitor.brokenLink(addr_t neighbor){
    int8_t i = get_route(neighbor);
    if (i != -1) {
      table[i].flags |= FLAG_BROKEN;
      signal RoutingTable.evicted(&table[i].info, REASON_UNREACHABLE);
      if (table[i].flags & (FLAG_NEW | FLAG_USED)) {
	cancel_timer(i, ROUTE_NEW);
	cancel_timer(i, ROUTE_USED);
	set_timer(i, ROUTE_DELETE);
      }
    }
  }

  event void LinkMonitor.refreshedLink(addr_t neighbor) {
    int8_t i = get_route(neighbor);
    if (i != -1) {
      replace_info(i, &table[i].info);
    }
  }

  void replace_info(uint8_t pos, const rt_info_t * route_info){
    table[pos].info = *route_info;
    table[pos].flags = FLAG_NEW;
    cancel_timers(pos);
    set_timer(pos, ROUTE_AGE_MIN);
    set_timer(pos, ROUTE_AGE_MAX);
    set_timer(pos, ROUTE_NEW);
  }

  /* Return the index of the route toward address if it exists, -1 otherwise */
  int8_t get_route(addr_t address){
    uint8_t i = 0;
    for(i=0;i<num_entries;i++){
      if(table[i].info.address == address){
	return i;
      }
    }
    return -1;
  }

  /* Remove a route from the table */
  void delete_route(uint8_t entry_id, reason_t r){
    table[entry_id].flags = FLAG_DELETED;
    cancel_timers(entry_id);
    dbg("dt", "DT: I'm deleting route number %hhu (for node %u).\n", entry_id, table[entry_id].info.address);
    signal RoutingTable.evicted(&table[entry_id].info, r);
  }

  /* compare two pieces of routing information
   * returns true if info1 > entry->info */
  bool is_superior(const rt_info_t * info1, const rt_entry_t * entry, dymo_msg_t msg_type){
    //a copy of the superior test in the specifications
    //with nil values discarded
    return ((info1->seqnum > entry->info.seqnum)
	    || ((info1->seqnum == entry->info.seqnum)
		&& info1->has_hopcnt
		&& entry->info.has_hopcnt
		&& ((info1->hopcnt < entry->info.has_hopcnt)
		    || ((info1->hopcnt == entry->info.has_hopcnt)
			&& ((msg_type == DYMO_RREP)
			    || (entry->flags & FLAG_BROKEN))))));
  }

  /* Start a timer for a route */
  void set_timer(uint8_t entry_id, rt_timer_t timer_id){
    call Timer.startOneShot[entry_id * NB_ROUTE_TIMERS + timer_id](timer_values[timer_id]);
  }

  /* Cancel a timer for a route */
  void cancel_timer(uint8_t entry_id, rt_timer_t timer_id){
    call Timer.stop[entry_id * NB_ROUTE_TIMERS + timer_id]();
  }

  /* Cancel all the timers of an entry */
  void cancel_timers(uint8_t entry_id){
    uint8_t i = entry_id * NB_ROUTE_TIMERS;
    for(i=0; i<NB_ROUTE_TIMERS; i++){
      call Timer.stop[i]();
    }
  }

#ifdef DYMO_MONITORING

  command uint8_t RoutingTableInfo.size(){
    return size;
  }

  command uint8_t RoutingTableInfo.maxSize(){
    return maxsize;
  }

  command uint8_t  RoutingTableInfo.getTableContent(rt_info_t * buf){
    uint8_t i=0, j=0;
    for(i=0; i<num_entries; i++){
      if( !(table[i].flags & (FLAG_DELETED | FLAG_BROKEN)) ){
	buf[j++] = table[i].info;
      }
    }
    return j;
  }

  command uint8_t RoutingTableInfo.getLinks(rt_link_t * buf){
    uint8_t i=0, j=0;
    for(i=0; i<num_entries; i++){
      if( !(table[i].flags & (FLAG_DELETED | FLAG_BROKEN)) ){
	buf[j].target = table[i].info.address;
	buf[j].nexthop = table[i].info.nexthop;
	j++;
      }
    }
    return j;
  }

#endif

 default event void RoutingTable.evicted(const rt_info_t * route_info, reason_t r){ }

}

