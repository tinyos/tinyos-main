/*
 * Copyright (c) 2010 Johns Hopkins University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * RPLDAORoutingEngineP.nc
 * @ author JeongGil Ko (John) <jgko@cs.jhu.edu>
 */

#include <RPL.h>
#include <in_cksum.h>
#include <ip.h>
#include <RPL.h>

generic module RPLDAORoutingEngineP(){
  provides {
    interface RPLDAORoutingEngine as RPLDAORouteInfo;
  }
  uses {
    interface Timer<TMilli> as DelayDAOTimer;
    interface Timer<TMilli> as RemoveTimer;
    interface Timer<TMilli> as GenerateDAOTimer;
    interface Random;
    interface DAOSend;
    interface IPAddress;
    interface Queue<dao_entry_t*> as SendQueue;
    interface Pool<dao_entry_t> as SendPool;
    interface RPLRoutingEngine as RPLRouteInfo;
  }
}

implementation{

  bool STORE_STATE = FALSE;
  uint32_t dao_rate = 20*1024U;
  uint32_t delay_dao = 256; // dao batches will be fired 256 ms after the first dao message is scheduled
  uint32_t remove_time = 60*1024U; // every 100 ms, check if elememts in the entry should be deleted -- only for storing nodes
  uint8_t dao_table_pos = 0;
  uint16_t DTSN = 0;
  uint16_t daoseq = 0;
  uint16_t init_daorank = 1;
  struct in6_addr MY_ADDR;
  struct in6_addr DEF_PREFIX;

  uint8_t PATH_SEQUENCE = 0;
  uint8_t PATH_CONTROL = 0;

  downwards_table_t downwards_table[DWT_SIZE];
  uint8_t downwards_table_count = 0;

  bool ip_compare(struct in6_addr *node1, struct in6_addr *node2){
    return !memcmp(node1, node2, sizeof(struct in6_addr));
  }

  uint8_t getIndex(struct in6_addr* addr){
    uint8_t i;
    for(i=0; i<downwards_table_count; i++){
      if(ip_compare(addr, &downwards_table[i].prefix)){
	return i;
      }
    }
    return downwards_table_count;
  }

#ifdef RPL_STORING_MODE
  error_t getRoute(struct in6_addr* dest, uint8_t* route, uint16_t* route_length){
    // CALLED WHEN 1) ROUTING HEADER IS NEEDED OR WHEN in RPL STORING MODE
    struct in6_addr next_hop;
    memcpy(&next_hop, dest, sizeof(struct in6_addr));

    *route_length = 0;

    if(!call RPLDAORouteInfo.hasPrefix(&next_hop)){
      //return *route_length+1;
      return -1;
    }
    // cpy the next hop addr
    memcpy(route+(*route_length * sizeof(struct in6_addr)), downwards_table[getIndex(&next_hop)].route, sizeof(struct in6_addr));
    *route_length  = 1;

    return 0; // no errors
  }
#else
  error_t getRoute(struct in6_addr* dest, struct rpl_route* route, uint16_t* length, void* payload){

    struct in6_addr next_hop;
    uint8_t i, route_length = 0;

    memcpy(&next_hop, dest, sizeof(struct in6_addr));

    call IPAddress.getLLAddr(&MY_ADDR);

    if(!call RPLDAORouteInfo.hasPrefix(&next_hop)){
      printfUART("No Pfx\n");
      return FAIL;
    }

    route->addr[route_length] = *dest; // final destination is the first element
    route_length ++;

    while(!ip_compare(&next_hop, &MY_ADDR)){

      if(!call RPLDAORouteInfo.hasPrefix(&next_hop)){
	printfUART("No Pfx\n");
	return FAIL;
      }

      route->addr[route_length] = *downwards_table[getIndex(&next_hop)].route;

      //printfUART("getting header %d %d %d %d %d \n", ntohs(next_hop.s6_addr16[7]), ntohs(downwards_table[getIndex(&next_hop)].route->s6_addr16[7]), route_length, getIndex(&next_hop), ntohs(route->addr[route_length].s6_addr16[7]));

      memcpy(&next_hop, downwards_table[getIndex(&next_hop)].route, sizeof(struct in6_addr));

      route_length ++;
    }

    for(i = * length ; i > 0 ; i --){
      // scoot everything back!
      *((uint8_t*)payload+i-1+(sizeof(struct in6_addr)*route_length)+8) = *((uint8_t*)payload+i-1);
    }

    route->segments_left = route_length;

    *length += ((route_length * sizeof(struct in6_addr)) + 8); // 8 is for the size of RH4

    return SUCCESS; // no errors
  }
#endif

  task void sendDAO(){
    dao_entry_t* dao_msg;
    struct ieee154_frame_addr addr_struct;
    struct in6_addr next_hop; // for now the next hop for the DAO is ONLY the desired parent on the path to the DODAG root
    struct dao_base_t* dao;

    // post sendDAO again until everything is transmitted
    if(call SendQueue.size() > 0 && call RPLRouteInfo.getMOP() != 0){

      dao_msg = call SendQueue.dequeue();

      //next_hop = (struct in6_addr*)ip_malloc(sizeof(struct in6_addr));
      next_hop = call RPLRouteInfo.getNextHop(DEF_PREFIX); // this should be my desired parent for now

      addr_struct.ieee_src.ieee_mode = IEEE154_ADDR_SHORT;
      addr_struct.ieee_dst.ieee_mode = IEEE154_ADDR_SHORT;

      addr_struct.ieee_dstpan = TOS_AM_GROUP;

      call IPAddress.resolveAddress(&next_hop, &addr_struct.ieee_dst);
      call IPAddress.resolveAddress(&MY_ADDR, &addr_struct.ieee_src);

      memcpy(&dao_msg->s_pkt.ip6_hdr.ip6_src, &MY_ADDR, sizeof(struct in6_addr));
      memcpy(&dao_msg->s_pkt.ip6_hdr.ip6_dst, &next_hop, sizeof(struct in6_addr));

      dao = (struct dao_base_t *) dao_msg->s_pkt.ip6_data->iov_base;
      //printfUART("DAO TX %d \n", ntohs(dao->target_option.target_prefix.s6_addr16[7]) );

      call DAOSend.sendDAO(&addr_struct, &dao_msg->s_pkt, (void*) &next_hop);

      call SendPool.put(dao_msg);

      if(call SendQueue.size()){
	// Once fired, shoot all the DAOs in the current sendqueue; Assume that there is no aggregation on DAO messages.
	post sendDAO();
      }
    }
  }

  command uint8_t RPLDAORouteInfo.hasPrefix(struct in6_addr* addr){
#ifdef RPL_STORING_MODE
    uint8_t i;
    //uint8_t result = 0;
    for(i=0 ; i < downwards_table_count ; i++){
      if(ip_compare(addr, &downwards_table[i].prefix)){
	return i+1;
      }
    }
    //return result;
    return 0;
#else
    uint8_t i;
    //bool result = FALSE;
    if(call RPLRouteInfo.getRank() != ROOT_RANK){
      //return FALSE;
      return 0;
    }else{
      for(i = 0 ; i < downwards_table_count ; i++){
	if(ip_compare(addr, &downwards_table[i].prefix)){
	  //result = i;
	  return i+1;
	}
      }
    }
    //return result;
    return 0;
#endif
  }

  command void RPLDAORouteInfo.startDAO(){

    call IPAddress.getLLAddr(&MY_ADDR);

    printfUART("START DAO \n");

#ifdef RPL_STORING_MODE
    STORE_STATE = TRUE;
    call RemoveTimer.startPeriodic(remove_time);
#else
    if(call RPLRouteInfo.getRank() != ROOT_RANK){
      STORE_STATE = FALSE;
    }else{
      STORE_STATE = TRUE;
      call RemoveTimer.startPeriodic(remove_time);
    }
#endif
    if(call RPLRouteInfo.getRank() != ROOT_RANK/*I am not root*/){
      call GenerateDAOTimer.startPeriodic(dao_rate);
    }

  }

  command bool RPLDAORouteInfo.getStoreState(){
    return STORE_STATE;
  }

  command struct in6_addr RPLDAORouteInfo.getNextHop(uint8_t nxt_hdr, struct in6_addr destination, struct rpl_route *routing_hdr, void* payload, uint16_t* plen){

    struct in6_addr next;
    uint16_t length;

#ifdef RPL_STORING_MODE
    //this is it! pretty simple huh?
    if(getRoute(&destination, (uint8_t*)&next, &length) != SUCCESS){
      *plen = 0;
      return next;
    }
    //printfUART(">>>>>> Get Next Hop for storing! %d \n", ntohs(next.s6_addr16[7]));

#else
    //struct in6_addr next_temp;
    struct rpl_route* temp;
    uint8_t i;
    //struct rpl_route route_header;
    length = ntohs(*plen);

    if(STORE_STATE){
      /*
      set the route list in the routing structure, in this case the route structure is for writing
      return the next hop
      */
      if(getRoute(&destination, routing_hdr, &length, payload) != SUCCESS){ // getRoute is going to set everything for me!
	*plen = 0;
	printfUART("plen = 0 \n");
	return next;
      }

      // the new payload will have the next hop addr
      routing_hdr->hdr_ext_len = routing_hdr->segments_left;
      routing_hdr->routing_type = 4;
      routing_hdr->compr = 0;
      routing_hdr->pad = 0;
      routing_hdr->next_header = nxt_hdr;

      temp = (struct rpl_route*) (uint8_t*) payload;

      temp->next_header = routing_hdr->next_header;
      temp->hdr_ext_len = routing_hdr->hdr_ext_len;
      temp->routing_type = routing_hdr->routing_type;
      temp->segments_left = routing_hdr->segments_left;
      temp->compr = routing_hdr->compr;
      temp->pad = routing_hdr->pad;

      for(i=0; i< routing_hdr->segments_left; i++)
	temp->addr[i] = routing_hdr->addr[i];

      printfUART("storingnode in non-storingmode %d %d %d %d \n",ntohs(routing_hdr->addr[routing_hdr->hdr_ext_len-routing_hdr->segments_left].s6_addr16[7]), routing_hdr->next_header, routing_hdr->routing_type, routing_hdr->segments_left);
    }

    /*
      reach in to the routing structure and get the next hop, in this case the route structure is for read
    */

    // payload is either from packet directly or added in the previous function.
    routing_hdr = (struct rpl_route*)(uint8_t*)payload;

    routing_hdr->segments_left --;

    if(routing_hdr->segments_left > 0){
      // still need to forward
      next = routing_hdr->addr[routing_hdr->segments_left - 1];
      //printfUART("><><>< %d %d %d %d \n",ntohs(next.s6_addr16[7]), routing_hdr->next_header, routing_hdr->routing_type, routing_hdr->segments_left);
    }else{
      // I am the last hop
      next = destination;
    }

    //printfUART(">>>>>> Get Next Hop for nonstoring! %d %d %d \n", routing_hdr->segments_left, length, ntohs(next.s6_addr16[7]));

    *plen = htons(length);
#endif
    return next;
  }

  event void GenerateDAOTimer.fired(){ // Initiate my own DAO messages

    error_t error;
    dao_entry_t* dao_msg;
    uint16_t length = sizeof(struct dao_base_t);
    struct in6_addr parent;

    dao_msg = call SendPool.get();

    if (dao_msg == NULL){
      return;
    }

    call IPAddress.setSource(&dao_msg->s_pkt.ip6_hdr);

    dao_msg->dao_base.icmpv6.type = ICMP_TYPE_ROUTER_ADV; // Is this type correct?
    dao_msg->dao_base.icmpv6.code = ICMPV6_CODE_DAO;
    dao_msg->dao_base.icmpv6.checksum = 0;
    dao_msg->dao_base.DAOsequence = daoseq;
    dao_msg->dao_base.instance_id.id = call RPLRouteInfo.getInstanceID(); // get instance ID from Rtg eng
    parent = call RPLRouteInfo.getNextHop(*call RPLRouteInfo.getDodagId());

    dao_msg->dao_base.target_option.type = 5;
    dao_msg->dao_base.target_option.option_length = 18;
    dao_msg->dao_base.target_option.prefix_length = sizeof(struct in6_addr); // length of my address
    memcpy(&dao_msg->dao_base.target_option.target_prefix, &MY_ADDR, sizeof(struct in6_addr)); // Cpy prefix
    
    dao_msg->dao_base.transit_info_option.type = 6;
    dao_msg->dao_base.transit_info_option.option_length = 22;
    dao_msg->dao_base.transit_info_option.path_sequence = PATH_SEQUENCE;
    dao_msg->dao_base.transit_info_option.path_control = PATH_CONTROL;
    dao_msg->dao_base.transit_info_option.path_lifetime = DEFAULT_LIFETIME;
    memcpy(&dao_msg->dao_base.transit_info_option.parent_address, &parent, sizeof(struct in6_addr)); //myaddr

    dao_msg->v[0].iov_base = (uint8_t *)&dao_msg->dao_base;
    dao_msg->v[0].iov_len  = length;
    dao_msg->v[0].iov_next = NULL;

    dao_msg->s_pkt.ip6_hdr.ip6_vfc = IPV6_VERSION;
    dao_msg->s_pkt.ip6_hdr.ip6_nxt = IANA_ICMP;
    dao_msg->s_pkt.ip6_hdr.ip6_plen = htons(length);
    dao_msg->s_pkt.ip6_data = &dao_msg->v[0];

    if(!call RPLRouteInfo.hasDODAG()){
      call SendPool.put(dao_msg);
      return;
    }

    error = call SendQueue.enqueue(dao_msg);

    if(error != SUCCESS){
      call SendPool.put(dao_msg);
      return;
    }else{
      if(!call DelayDAOTimer.isRunning()){
	call DelayDAOTimer.startOneShot(delay_dao);
      }
    }
  }

  event void DelayDAOTimer.fired(){
    post sendDAO();
  }

  event void RemoveTimer.fired(){
    // check stored table's life-time
    uint8_t i, j;
    if (!STORE_STATE)
      return;

    for(i = 0 ; i < downwards_table_count ; i++){
      downwards_table[i].lifetime -= delay_dao;
      if(downwards_table[i].lifetime <= delay_dao){
	for(j = i ; j < downwards_table_count-1 ; j++){
	  downwards_table[j] = downwards_table[j+1];
	}
	downwards_table[downwards_table_count-1].lifetime = 0;
	downwards_table_count --;
      }
    }

  }

  event void DAOSend.recvDAO(struct ip6_hdr *iph, void *payload, struct ip6_metadata *meta){
 
    dao_entry_t* dao_msg;
    error_t error;
    uint8_t i;
    struct dao_base_t *dao = (struct dao_base_t *)payload; // This is where the message is actually casted

#ifdef RPL_STORING_MODE
    if((i = call RPLDAORouteInfo.hasPrefix((struct in6_addr*)&dao->target_option.target_prefix))){
      // already have this prefix
      if(ip_compare(downwards_table[i-1].route, &iph->ip6_src)){
	// same old destination
	/*
	printfUART("DAO RX -- Storing mode -- has prefix %d %d %d \n", downwards_table_count, ntohs(dao->target_option.target_prefix.s6_addr16[7]), ntohs(iph->ip6_src.s6_addr16[7]));
	for(i = 0 ; i < downwards_table_count ; i++){
	  printfUART("%d ", ntohs(downwards_table[i].prefix.s6_addr16[7]));
	}
	printfUART("\n");
	*/
      }else{
	// new next hop for an existing downswards node
	call RPLRouteInfo.setDTSN(call RPLRouteInfo.getDTSN()+1);
      }
    }else{
      // new prefix
      memcpy(&downwards_table[downwards_table_count].prefix, &dao->target_option.target_prefix, sizeof(struct in6_addr));
      // all nodes just need to store the previous hop
      memcpy(downwards_table[downwards_table_count].route, &iph->ip6_src, sizeof(struct in6_addr));
      // only previous hop so 1 element
      downwards_table[downwards_table_count].route_length = 1;
      // lifetime
      downwards_table[downwards_table_count].lifetime = dao->transit_info_option.path_lifetime;
      // for next element
      downwards_table_count ++;
      printfUART("DAO RX -- Storing mode -- new prefix %d %d %d \n", downwards_table_count, ntohs(dao->target_option.target_prefix.s6_addr16[7]), ntohs(iph->ip6_src.s6_addr16[7]));
    }
#else
    //struct in6_addr temp;
    //if(call RPLRouteInfo.getRank() != ROOT_RANK){
    if(!STORE_STATE){
      // nothing to do here!
    }else{
      // perform path saving process if I shoud store // I am the root probably!!
      if((i = call RPLDAORouteInfo.hasPrefix((struct in6_addr*)&dao->target_option.target_prefix))){
	// already have this prefix
	if(ip_compare(downwards_table[i-1].route, &iph->ip6_src)){
	  // same old destination
	  /*
	  printfUART("DAO RX -- Storing mode -- has prefix %d %d %d \n", downwards_table_count, ntohs(dao->target_option.target_prefix.s6_addr16[7]), ntohs(iph->ip6_src.s6_addr16[7]));
	  for(i = 0 ; i < downwards_table_count ; i++){
	    printfUART("%d ", ntohs(downwards_table[i].prefix.s6_addr16[7]));
	  }
	  printfUART("\n");
	  */
	}else{
	  // new next hop for an existing downswards node
	  call RPLRouteInfo.setDTSN(call RPLRouteInfo.getDTSN()+1);
	}
      }else{
	memcpy(&downwards_table[downwards_table_count].prefix, &dao->target_option.target_prefix, sizeof(struct in6_addr));
	// all nodes just need to store the previous hop
	memcpy(downwards_table[downwards_table_count].route, &dao->transit_info_option.parent_address, sizeof(struct in6_addr));
	// only previous hop so 1 element
	downwards_table[downwards_table_count].route_length = 1;
	// lifetime
	downwards_table[downwards_table_count].lifetime = dao->transit_info_option.path_lifetime;

	downwards_table_count ++;
	printfUART("DAO RX -- non Storing mode -- new prefix %d %d %d \n", downwards_table_count, ntohs(dao->target_option.target_prefix.s6_addr16[7]), ntohs(iph->ip6_src.s6_addr16[7]));
      }
    }
#endif

    /***********************************************************************/
    // FROM THIS POINT, ITS ABOUT FORWARDING THE DAO INFORMATION UPWARDS!!!
    /***********************************************************************/

    if(call RPLRouteInfo.getRank() == ROOT_RANK){
      // no need to futher process packets
      return;
    }

    dao_msg = call SendPool.get();

    if (dao_msg == NULL){
      return;
    }

    // NO MODIFICATION TO DAO's RR-LIST NEEDED! -- just make sure I keep what I have and the prefix

    printfUART("Continue! %d \n", ntohs(iph->ip6_plen));
    memcpy(&dao_msg->s_pkt.ip6_hdr, iph, sizeof(struct ip6_hdr));

    // cpy new payload information
    memcpy(&dao_msg->dao_base, (uint8_t*)payload, sizeof(struct dao_base_t));

    dao_msg->v[0].iov_base = (uint8_t *)&dao_msg->dao_base;
    dao_msg->v[0].iov_len = ntohs(iph->ip6_plen);
    dao_msg->v[0].iov_next = NULL;

    dao_msg->s_pkt.ip6_data = &dao_msg->v[0];

    error = call SendQueue.enqueue(dao_msg);
    if(error != SUCCESS){
      call SendPool.put(dao_msg);
      return;
    }else{
      if(!call DelayDAOTimer.isRunning()){
	call DelayDAOTimer.startOneShot(delay_dao);
      }
    }
  }
}
