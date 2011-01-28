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
 * RPLRankC.nc
 * @ author JeongGil Ko (John) <jgko@cs.jhu.edu>
 */

/*
 * Copyright (c) 2010 Stanford University. All rights reserved.
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
 * @ author Yiwei Yao <yaoyiwei@stanford.edu>
 */

#include <PrintfUART.h>
#include <RPL.h>
#include <lib6lowpan/ip_malloc.h>
module RPLRankP{
  provides{
    interface RPLRank as RPLRankInfo;
    interface StdControl;
    interface IP as IP_DIO_Filter;
  }
  uses {
    interface IP as IP_DIO;
    interface RPLRoutingEngine as RouteInfo;
    interface Leds;
    interface IPAddress;
    interface ForwardingTable;
    interface ForwardingEvents;
    interface RPLOF;
  }
}

implementation {

  uint16_t nodeRank = INFINITE_RANK; // 0 is the initialization state
  uint16_t minRank = INFINITE_RANK;
  bool leafState = FALSE;
  /* SDH : this is essentially the Default Route List */
  struct in6_addr prevParent;
  uint32_t parentChanges = 0;
  uint8_t parentNum = 0;
  uint16_t minMetric = MAX_ETX;
  uint16_t desiredParent = MAX_PARENT;
  uint16_t VERSION = 0;
  uint16_t nodeEtx = 10;
  uint8_t MAX_RANK_INCREASE = 1;
  
  uint8_t etxConstraint;
  uint32_t latencyConstraint;
  bool hasConstraint[2] = {FALSE,FALSE}; //hasConstraint[0] represents ETX, hasConstraint[1] represent Latency
  
  struct in6_addr DODAGID;
  struct in6_addr DODAG_MAX;
  uint8_t METRICID; //which metric
  uint16_t OCP;
  uint32_t myQDelay = 1.0;
  bool hasOF = FALSE;
  uint8_t Prf = 0xFF;
  uint8_t alpha; //configuration parameter
  uint8_t beta;
  bool ignore = FALSE;
  bool m_running = FALSE;
  uint8_t divideRank = 10;

  void resetValid();
  void getNewRank();

#undef printfUART
#define printfUART(X, fmt ...) ;
#define compare_ipv6(node1, node2) (!memcmp((node1), (node2), sizeof(struct in6_addr)))

  command error_t StdControl.start() { //initialization
    uint8_t indexset;

    DODAG_MAX.s6_addr16[7] = htons(0);

    memcpy(&DODAGID, &DODAG_MAX, sizeof(struct in6_addr));

    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      parentSet[indexset].valid = FALSE;
    }

    m_running = TRUE;
    return SUCCESS;
  }

  command error_t StdControl.stop() { 
    m_running = FALSE;
    return SUCCESS;
  }

  // declare the I am the root
  command void RPLRankInfo.declareRoot(){ //done
    minMetric = 10;
    nodeRank = 1;
  }

  command bool RPLRankInfo.validInstance(uint8_t instanceID){ //done
    return TRUE;
  }

  // I am no longer a root
  command void RPLRankInfo.cancelRoot(){ //done
  }

  uint8_t getParent(struct in6_addr *node);
  
  // return the rank of the specified IP addr
  command uint16_t RPLRankInfo.getRank(struct in6_addr *node){ //done
    uint8_t indexset;
    struct in6_addr my_addr;
    call IPAddress.getLLAddr(&my_addr);
    if(compare_ipv6(&my_addr, node)){
      return nodeRank;
    }
    indexset = getParent(node);
    if (indexset != MAX_PARENT){
      return parentSet[indexset].rank;
    }
    return nodeRank;
  }

  command error_t RPLRankInfo.getDefaultRoute(struct in6_addr *next) {
    if (parentNum) {
      memcpy(next, &parentSet[desiredParent].parentIP, sizeof(struct in6_addr));
      return SUCCESS;
    }
    return FAIL;
  }

  bool exceedThreshold(uint8_t indexset, uint8_t ID) { //done
    return parentSet[indexset].etx_hop > ETX_THRESHOLD;
  }

  command bool RPLRankInfo.compareAddr(struct in6_addr *node1, struct in6_addr *node2){ //done
    return compare_ipv6(node1, node2);
  }

  //return the index of parent
  uint8_t getParent(struct in6_addr *node) { //done
    uint8_t indexset;
    if (parentNum == 0) {
      return MAX_PARENT;
    }
    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      if (compare_ipv6(&(parentSet[indexset].parentIP),node) && 
          parentSet[indexset].valid) {
	return indexset;
      }
    }
    return MAX_PARENT;
  }

  // return if IP is in parent set
  command bool RPLRankInfo.isParent(struct in6_addr *node) { //done
    return (getParent(node) != MAX_PARENT);
  }

  /*
  // new iteration has begun, all need to be cleared
  command void RPLRankInfo.notifyNewIteration(){ //done
    parentNum = 0;
    resetValid();
  }
  */

  void resetValid(){    //done
    uint8_t indexset;
    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      parentSet[indexset].valid = FALSE;
    }
  }

  // inconsistency is seen for the link with IP
  // record this as part of entry in table as well
  // Other layers will report this information
  command void RPLRankInfo.inconsistencyDetected(){ //done

    printfUART("incons! \n");
    parentNum = 0;
    call RPLOF.resetRank();
    nodeRank = INFINITE_RANK;
    minMetric = MAX_ETX;
    desiredParent = MAX_PARENT;
    resetValid();

    //parentNum = 0;
    //resetValid();
  }

  // ping rank component if there are parents
  command uint8_t RPLRankInfo.hasParent(){ //done
    return parentNum;
  }

  command bool RPLRankInfo.isLeaf(){ //done
    //return TRUE;
    return leafState;
  }

  uint8_t getPreExistingParent(struct in6_addr *node) {
    // just find if there are any pre existing information on this node...
    uint8_t indexset;
    if (parentNum == 0) {
      return MAX_PARENT;
    }

    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      if (compare_ipv6(&(parentSet[indexset].parentIP),node)) {
	return indexset;
      }
    }
    return MAX_PARENT;
  }

  command uint16_t RPLRankInfo.getEtx(){ //done
    uint8_t i;

    if(nodeRank == 1){
      return 10; // this is the min etx, reserved  only for the root
    }

    i = getParent(call RPLOF.getParent());

    if(i != MAX_PARENT)
      nodeEtx = parentSet[i].etx_hop + parentSet[i].etx;
    else 
      nodeEtx = nodeRank * divideRank;

    return nodeEtx;
  }

  void insertParent(parent_t parent) {
    uint8_t indexset = getPreExistingParent(&parent.parentIP);

    if(indexset != MAX_PARENT) // we have previous information
      {
	parentSet[indexset].valid = TRUE;
	if(parentSet[indexset].etx_hop > INIT_ETX && parentSet[indexset].etx_hop < BLIP_L2_RETRIES)
	  parent.etx_hop = parentSet[indexset].etx_hop-10;
	else
	  parent.etx_hop = INIT_ETX;

	parentSet[indexset] = parent;
	parentNum++;
	printfUART("Parent Added %d \n",parentNum);
	return;
      }

    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      if (!parentSet[indexset].valid) {
	parentSet[indexset] = parent;
	parentNum++;
	break;
      }
    }
    printfUART("Parent Added 2 %d \n",parentNum);
  }

  void evictParent(uint8_t indexset) {//done
    parentSet[indexset].valid = FALSE;
    parentNum--;
    printfUART("Evict parent %d \n", parentNum);
    if (parentNum == 0) {
      //should do something
      call RouteInfo.resetTrickle();
    }
  }

  /* check and remove parents on rank change */
  void evictAll() {//done
    uint8_t indexset;
    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      if (parentSet[indexset].valid && parentSet[indexset].rank >= nodeRank) {
	parentSet[indexset].valid = FALSE;
	parentNum--;
	printfUART("Evict all %d \n", parentNum);
      }
    }
  }

  command void RPLRankInfo.setQueuingDelay(uint32_t delay){    
    myQDelay = delay;
  }

#if 0
  event error_t ForwardingEvents.deleteHeader(struct ip6_hdr *iph, void* payload){
    uint16_t len;
    /* Reconfigure length */
    len = ntohs(iph->ip6_plen);
    printfUART("delete header %d \n",len);
    len = len - sizeof(rpl_data_hdr_t);;
    iph->ip6_plen = htons(len);

    /* Move data back up */
    memcpy(payload, (uint8_t*)payload + sizeof(rpl_data_hdr_t), len);

    /* configure length*/
    //&length -= sizeof(sizeof(rpl_data_hdr_t));

    return SUCCESS;
  }
#endif


  event bool ForwardingEvents.initiate(struct ip6_packet *pkt,
                                       struct in6_addr *next_hop) {

    struct ip_iovec v;
    uint16_t len; 
    rpl_data_hdr_t data_hdr;

    return TRUE;

    if(pkt->ip6_hdr.ip6_nxt == IANA_ICMP)
      return TRUE;

    data_hdr.ip6_ext_outer.ip6e_nxt = pkt->ip6_hdr.ip6_nxt;
    data_hdr.ip6_ext_outer.ip6e_len = sizeof(rpl_data_hdr_t);

    data_hdr.ip6_ext_inner.ip6e_nxt = RPL_HBH_RANK_TYPE; /* well, this is actually the type */
    data_hdr.ip6_ext_inner.ip6e_len = sizeof(rpl_data_hdr_t) - sizeof(struct ip6_ext);
    data_hdr.o_bit = 0;
    data_hdr.r_bit = 0;
    data_hdr.f_bit = 0;
    data_hdr.reserved = 0;
    data_hdr.instance_id.id = call RouteInfo.getInstanceID();
    data_hdr.senderRank = nodeRank;

    pkt->ip6_hdr.ip6_nxt = IPV6_HOP;

    len = ntohs(pkt->ip6_hdr.ip6_plen);

    printfUART("make header %d %d\n", pkt->ip6_hdr.ip6_nxt, len);
    /* add the header */
    v.iov_base = (uint8_t*) &data_hdr;
    v.iov_len = sizeof(rpl_data_hdr_t);
    v.iov_next = pkt->ip6_data; // original upper layer goes here!
    
    /* increase length in ipv6 header and relocate beginning*/
    pkt->ip6_data = &v;
    len = len + v.iov_len;
    pkt->ip6_hdr.ip6_plen = htons(len);

    printfUART("set data header to %d %d %d\n", data_hdr.instance_id.id, data_hdr.senderRank, len);
    return TRUE;

  }

  /**
   * Signaled by the forwarding engine for each packet being forwarded.
   *
   * If we return FALSE, the stack will drop the packet instead of
   * doing whatever was in the routing table.
   *
   */
  event bool ForwardingEvents.approve(struct ip6_hdr *iph, struct ip6_route *route,
                                      struct in6_addr *next_hop) {
    rpl_data_hdr_t* data_hdr;
    bool inconsistent = FALSE;

    data_hdr = (rpl_data_hdr_t*) route;

    printfUART("approve test: %d %d %d %d %d \n", data_hdr->senderRank, data_hdr->instance_id.id, nodeRank, data_hdr->o_bit, call RPLRankInfo.getRank(next_hop));

    /* SDH : we'd want to dispatch on the instance id if there are
       multiple dags */

    if (data_hdr->senderRank == 1){
      data_hdr->o_bit = 1;
      goto approve;
    }

    if (data_hdr->o_bit && data_hdr->senderRank > nodeRank) {
      /* loop */
      inconsistent = TRUE;
    } else if (!data_hdr->o_bit && data_hdr->senderRank < nodeRank) {
      inconsistent = TRUE;
    }

    if (call RPLRankInfo.getRank(next_hop) >= nodeRank){
      /* Packet is heading down if the next_hop rank is not smaller than the current one (not in the parent set) */
      /* By the time I am here, it means that there is a next hop but if this is not in my parent set, then it should be downward*/
      data_hdr->o_bit = 1;
    }

    if (inconsistent) {
      if (data_hdr->r_bit) {
        /*  this is not the first time  */
        /*  ditch this packet! */
	call RouteInfo.inconsistency();
        return FALSE;
      } else {
        /* just mark it */
        data_hdr->r_bit = 1;
	//chooseDesired();
	call RPLOF.recomputeRoutes();
	//recaRank();
	getNewRank();
	//call RouteInfo.inconsistency();
	goto approve;
      }
    }

  approve:
    printfUART("Approving: %d %d %d\n", data_hdr->senderRank, data_hdr->instance_id.id, inconsistent);
    data_hdr->senderRank = nodeRank;
    return TRUE;
  }

  /*  Compute ETX! */
  event void ForwardingEvents.linkResult(struct in6_addr *node, struct send_info *info) {
    uint8_t indexset;
    uint8_t etx_now = info->link_transmissions;

    printfUART("linkResult: ");
    //printfUART_in6addr(node);
    printfUART(" [%i]\n", info->link_transmissions);

    if(nodeRank == 1) { //root
      return;
    }

    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      if (parentSet[indexset].valid && 
          compare_ipv6(&(parentSet[indexset].parentIP), node))
	break;
    }

    if (indexset != MAX_PARENT) { // not empty...
      parentSet[indexset].etx_hop = 
        (parentSet[indexset].etx_hop * 5 + etx_now * 10 * 5) / 10;

      if (exceedThreshold(indexset, METRICID)) {
	evictParent(indexset);
	if (indexset == desiredParent && parentNum > 0)
	  call RPLOF.recomputeRoutes();
	//chooseDesired();
      }

      else if(etx_now > 1 && parentNum > 1){ // if a packet is not transmitted on its first try... see if there is something better...
	call RPLOF.recomputeRoutes();
      }

      getNewRank();

      printfUART(">> P_ETX UPDATE %d %d %d %d %d \n", indexset, 
                 parentSet[indexset].etx_hop, etx_now, 
                 ntohs(parentSet[indexset].parentIP.s6_addr16[7]), nodeRank);
      return;
    }
    // not contained in either parent set, do nothing
  }

  /* old <= new, return true;  */
  bool compareParent(parent_t oldP, parent_t newP) { 
    return (oldP.etx_hop + oldP.etx) <= (newP.etx_hop + newP.etx);
  }

  /*
  void performConsCheck() {
    uint8_t indexset = 0;
    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      if (!checkConstraint(0, latencyConstraint, 
                           parentSet[indexset].etx, etxConstraint, 
                           METRICID, indexset)) {
	parentSet[indexset].valid = FALSE;
      }
    }
  }
  */

  void getNewRank(){

    uint16_t prevRank = nodeRank;

    call RPLOF.recalcualateRank();
    nodeRank = call RPLOF.getRank();

    if(nodeRank < minRank)
      minRank = nodeRank;

    // did the node rank get worse than the limit? 
    if (nodeRank > prevRank && 
        nodeRank - minRank >= MAX_RANK_INCREASE && MAX_RANK_INCREASE != 0) {
      // this is inconsistency!
      printfUART("Inconsistent!\n");
      nodeRank = 0xFFFF;
      minRank = 0xFFFF;
      call RouteInfo.inconsistency();
    }

  }

  void parseDIO(struct ip6_hdr *iph, struct dio_base_t *dio) { 
    uint16_t pParentRank;
    struct in6_addr rDODAGID;
    uint16_t etx = 0xFFFF;
    parent_t tempParent;
    uint8_t parentIndex;
    uint16_t preRank;
    uint8_t tempPrf;
    bool newDodag = FALSE;

    struct dio_body_t* dio_body;
    struct dio_metric_header_t* dio_metric_header;
    struct dio_etx_t* dio_etx;
    struct dio_dodag_config_t* dio_dodag_config;
    struct dio_prefix_t* dio_prefix;
    uint8_t* newPoint;
    uint16_t trackLength = ntohs(iph->ip6_plen);

    /* I am root */
    if (nodeRank == 1) return; 

    /* new iteration */
    if (dio->version != VERSION && compare_ipv6(&dio->dodagID, &DODAGID)) {
      printfUART("new iteration!\n");
      parentNum = 0;
      VERSION = dio->version;
      call RPLOF.resetRank();
      nodeRank = INFINITE_RANK;
      minRank = INFINITE_RANK;
      minMetric = MAX_ETX;
      desiredParent = MAX_PARENT;
      resetValid();
    }

    if (dio->dagRank >= nodeRank && nodeRank != INFINITE_RANK /*&& getParent(iph->ip6_src) != MAX_PARENT*/) return;

    printfUART("DIO in Rank %d %d %d %d\n", ntohs(iph->ip6_src.s6_addr16[7]), dio->dagRank, nodeRank, parentNum);
    //printfUART_in6addr(&iph->ip6_src);
    //printfUART("\n");
    
    pParentRank = dio->dagRank;
    // DODAG ID in this DIO packet (received DODAGID)

    memcpy(&rDODAGID, &dio->dodagID, sizeof(struct in6_addr)); 
    tempPrf = dio->dag_preference;

    if (!compare_ipv6(&DODAGID, &DODAG_MAX) && 
        !compare_ipv6(&DODAGID, &rDODAGID)) { 
      // I have a DODAG but this packet is from a new DODAG
      if (Prf < tempPrf) { //ignore
	printfUART("LESS PREFERENCE IGNORE \n");
	ignore = TRUE;
	return;
      } else if (Prf > tempPrf) { //move
        printfUART("MOVE TO NEW DODAG \n");
	Prf = tempPrf;
	memcpy(&DODAGID, &rDODAGID, sizeof(struct in6_addr));
	parentNum = 0;
	VERSION = dio->version;
	call RPLOF.resetRank();
	nodeRank = INFINITE_RANK;
	minRank = INFINITE_RANK;
	minMetric = MAX_ETX;
	desiredParent = MAX_PARENT;
	resetValid();
      } else { // it depends
        //printfUART("MOVE TO NEW DODAG %d %d\n",compare_ipv6(&DODAGID, &DODAG_MAX), compare_ipv6(&DODAGID, &rDODAGID));
	newDodag = TRUE;
      }
    } else if (compare_ipv6(&DODAGID, &DODAG_MAX)) { //not belong to a DODAG yet
      printfUART("TOTALLY NEW DODAG \n");
      Prf = tempPrf;
      memcpy(&DODAGID, &rDODAGID, sizeof(struct in6_addr));
      parentNum = 0;
      VERSION = dio->version;
      call RPLOF.resetRank();
      nodeRank = INFINITE_RANK;
      minRank = INFINITE_RANK;
      minMetric = MAX_ETX;
      desiredParent = MAX_PARENT;
      resetValid();
    } else { // same DODAG
      printfUART("FROM SAME DODAG \n");
      Prf = tempPrf; // update prf
    }

    /////////////////////////////Collect data from DIOs/////////////////////////////////
    trackLength -= sizeof(struct dio_base_t);
    newPoint = (uint8_t*)(struct dio_base_t*)(dio + 1);
    dio_body = (struct dio_body_t*) newPoint;

    METRICID = 0;
    OCP = 0;

    // SDH : TODO : make some #defs for DODAG constants

    if (dio_body->type == 2) { // this is metric

      trackLength -= sizeof(struct dio_body_t);

      newPoint = (uint8_t*)(struct dio_body_t*)(dio_body + 1);
      dio_metric_header = (struct dio_metric_header_t*) newPoint;
      trackLength -= sizeof(struct dio_metric_header_t);

      if (dio_metric_header->routing_obj_type) {
	// etx metric
        // SDH : double cast
	// newPoint = (uint8_t*)(struct dio_metric_header_t*)(dio_metric_header + 1);
        newPoint = (uint8_t*)(dio_metric_header + 1);
	dio_etx = (struct dio_etx_t*)newPoint;
	trackLength -= sizeof(struct dio_etx_t);
	etx = dio_etx->etx;
	printfUART("ETX RECV %d \n", etx);
	METRICID = 7;
	newPoint = (uint8_t*)(struct dio_etx_t*)(dio_etx + 1);
      }
    }else{
      etx = pParentRank*10;
      printfUART("No ETX %d \n", dio_body->type);
    }

    /* SDH : what is type 3? */
    dio_prefix = (struct dio_prefix_t*) newPoint;

    if (trackLength > 0 && dio_prefix->type == 3) {
      trackLength -= sizeof(struct dio_prefix_t);
      if (ignore == FALSE){
        /* SDH : this will be a call to NeighborDiscovery */
        /* although we might want to make a PrefixManager component... */
	// New Prefix!!!!
	// TODO: Save prefix somewhere and make it a searchable command
      }
    }

    /* SDH : type 4 is a configuration header. */
    dio_dodag_config = (struct dio_dodag_config_t*) newPoint;

    printfUART("%d %d %d %d %d \n", trackLength, METRICID, dio_body->type, dio_prefix->type, dio_dodag_config->type);

    if (trackLength > 0 && dio_dodag_config->type == 4) {
      // this is configuration header
      trackLength -= sizeof(struct dio_dodag_config_t);

      printfUART(" > %d %d %d %d %d \n", trackLength, METRICID, dio_dodag_config->type, ignore, dio_dodag_config->ocp);

      if (ignore == FALSE) {

	OCP = dio_dodag_config->ocp;

	printfUART("CONFIGURATION! %d %d %d \n", trackLength, ignore, dio_dodag_config->MaxRankInc);
	MAX_RANK_INCREASE = dio_dodag_config->MaxRankInc;
	call RouteInfo.setDODAGConfig(dio_dodag_config->DIOIntDoubl, 
                                      dio_dodag_config->DIOIntMin, 
				      dio_dodag_config->DIORedun, 
                                      dio_dodag_config->MaxRankInc, 
                                      dio_dodag_config->MinHopRankInc);

	printfUART("Doub %d, min %d, redun %d, maxrank %d, minhop %d \n", 
		   dio_dodag_config->DIOIntDoubl, 
		   dio_dodag_config->DIOIntMin, 
		   dio_dodag_config->DIORedun, 
		   dio_dodag_config->MaxRankInc, 
		   dio_dodag_config->MinHopRankInc);
      }
      printfUART("CONFIGURATION! %d %d %d %d %d\n", trackLength, ignore, dio_dodag_config->MaxRankInc, METRICID, OCP);
      //OCP = 0; // temp for interop -- I know that Contiki is using OF0
    }

    ///////////////////////////////////////////////////////////////////////////////////

    printfUART("PR %d NR %d OCP %d MID %d \n", pParentRank, nodeRank, OCP, METRICID);

    if(pParentRank >= nodeRank && nodeRank != 0xFFFF){
      return;
    }

    // temporaily keep the parent information first
    memcpy(&tempParent.parentIP, &iph->ip6_src, sizeof(struct in6_addr)); //may be not right!!!
    tempParent.rank = pParentRank;
    tempParent.etx_hop = INIT_ETX;
    tempParent.valid = TRUE;
    tempParent.etx = etx;


    if(!call RPLOF.objectSupported(METRICID) || !call RPLOF.OCP(OCP)){
      // either I dont know the metric object or I don't support the OF
      printfUART("LEAF STATE! \n");
      /*
      Prf = tempPrf;
      memcpy(&DODAGID, &rDODAGID, sizeof(struct in6_addr));
      parentNum = 0;
      VERSION = dio->version;
      minMetric = MAX_ETX;
      desiredParent = MAX_PARENT;
      resetValid();
      */
      insertParent(tempParent);
      call RPLOF.recomputeRoutes();
      //getNewRank(); no need to compute routes when I am going to stay as a leaf!
      nodeRank = 0xFFFF;
      leafState = TRUE;
      return;
    }

    if ((parentIndex = getParent(&iph->ip6_src)) != MAX_PARENT) { 
      // parent already there and the rank is useful

      printfUART("HOW many parents 1 ? %d %d \n", parentNum, newDodag);

      if(newDodag){
	// old parent has to move to a new DODAG now
	if (parentNum != 0) {
	  //chooseDesired();
	  call RPLOF.recomputeRoutes(); // we do this to make sure that this parent is still the best and it is worth moving
	  
	  if (!compareParent(parentSet[desiredParent], tempParent)) {
	    // the new dodag is not from my desired parent node
	    Prf = tempPrf;
	    memcpy(&DODAGID, &rDODAGID, sizeof(struct in6_addr));
	    parentNum = 0;
	    VERSION = dio->version;
	    minMetric = MAX_ETX;
	    desiredParent = MAX_PARENT;
	    resetValid();
	    insertParent(tempParent);
	    call RPLOF.recomputeRoutes();
	    getNewRank();
	  } else {
	    // I have a better node in the current DODAG so I am not moving!
	    call RPLOF.recomputeRoutes();
	    getNewRank();
	    evictAll();
	    ignore = TRUE;
	  }
	} else {
	  // not likely to happen but this is a new DODAG...
	  Prf = tempPrf;
	  memcpy(&DODAGID, &rDODAGID, sizeof(struct in6_addr));
	  parentNum = 0;
	  VERSION = dio->version;
	  minMetric = MAX_ETX;
	  desiredParent = MAX_PARENT;
	  resetValid();
	  insertParent(tempParent);
	  call RPLOF.recomputeRoutes();
	  getNewRank();
	}

      }else{
	// this DIO is just from a parent that I know already, update and re-evaluate
	printfUART("known parent -- update\n");
	parentSet[parentIndex].rank = pParentRank; //update rank
	parentSet[parentIndex].etx = pParentRank*10;
	call RPLOF.recomputeRoutes();
	getNewRank();
	evictAll();
	ignore = TRUE;
      }

    }else{
      // this parent is not in my routing table

      printfUART("HOW many parents? %d \n", parentNum);

      if(parentNum > MAX_PARENT) // ><><><><><>< how do i share the parent count?
	return;

      // at this point know that its a meaningful packet from a new node and we have space to store
      
      printfUART("New parent %d %d %d\n", ntohs(iph->ip6_src.s6_addr16[7]), tempParent.etx_hop, parentNum);

      if(newDodag){
	// not only is this parent new but we have to move to a new DODAG now
	printfUART("New DODAG \n");
	if (parentNum != 0) {
	  call RPLOF.recomputeRoutes(); // make sure that I don't have an alternative path on this DODAG
	  if (!compareParent(parentSet[desiredParent], tempParent)) {
	    // parentIndex == desiredParent, parentNum != 0, !compareParent
	    printfUART("changing DODAG\n");
	    Prf = tempPrf;
	    memcpy(&DODAGID, &rDODAGID, sizeof(struct in6_addr));
	    parentNum = 0;
	    VERSION = dio->version;
	    minMetric = MAX_ETX;
	    desiredParent = MAX_PARENT;
	    resetValid();
	    insertParent(tempParent);
	    call RPLOF.recomputeRoutes();
	    getNewRank();
	  } else {
	    //do nothing
	    ignore = TRUE;
	  }
	} else {
	  // This is the first DODAG I am registering ... or the once before are all goners already
	  printfUART("First DODAG\n");
	  Prf = tempPrf;
	  memcpy(&DODAGID, &rDODAGID, sizeof(struct in6_addr));
	  parentNum = 0;
	  VERSION = dio->version;
	  minMetric = MAX_ETX;
	  desiredParent = MAX_PARENT;
	  resetValid();
	  insertParent(tempParent);
	  call RPLOF.recomputeRoutes();
	  getNewRank();
	}
      }else{
	// its a new parent from the current DODAG .. so no need for DODAG configuarion just insert
	printfUART("Same DODAG %d \n", parentNum);
	insertParent(tempParent);
	call RPLOF.recomputeRoutes();
	preRank = nodeRank;
	getNewRank();
	evictAll();
      }
    }
  }

  /* 
   * Processing for incomming DIO, DAO, and DIS messages.
   *
   * SDH : we should not snoop on these from the forwarding engine;
   * instead we now go through the IPProtocols component to receive
   * them the normal way through the ICMP stack.  Things like
   * verifying the checksum can go in there.
   *
   */
  event void IP_DIO.recv(struct ip6_hdr *iph, void *payload, 
                         size_t len, struct ip6_metadata *meta){
    struct dio_base_t *dio;
    int i;
    uint8_t pay[100];
    dio = (struct dio_base_t *) payload;

    if (!m_running) return;

    /*
    memcpy(pay, payload, len);
    printfUART("len: %d ",len);
    for(i=0; i<len; i++)
      printfUART("%.2x ",pay[i]);
    printfUART("\n");
    */

    printfUART_in6addr(&iph->ip6_src);
    printfUART(" >  I GOT %d %d %d %d %d!!\n", iph->ip6_nxt, dio->icmpv6.code, dio->dagRank, nodeRank, parentNum);

    //leafState = FALSE;
    if (nodeRank > dio->dagRank) {

      parseDIO(iph, dio);

      if (!ignore) {
        /* SDH : where did this go? */
        signal IP_DIO_Filter.recv(iph, payload, len, meta);
      }
      ignore = FALSE;
    }
  }

  command error_t IP_DIO_Filter.send(struct ip6_packet *msg) {
    return call IP_DIO.send(msg);
  }

  event void IPAddress.changed(bool global_valid) {}
}
