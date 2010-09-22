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
#include <ip_malloc.h>
module RPLRankP{
  provides{
    interface RPLRank as RPLRankInfo;
    interface IPLower;
    interface StdControl;
    interface RPLForwardingSend;
    interface DAOSend;
  }
  uses {
    interface RPLRoutingEngine as RouteInfo;
    interface IPLower as SubIPLower;
    interface Leds;
    interface IPAddress;
  }
}

implementation {

  uint16_t nodeRank = INFINITE_RANK; // 0 is the initialization state
  bool leafState = TRUE;
  parent_t parentSet[MAX_PARENT];

  uint8_t parentNum = 0;
  uint16_t minMetric = MAX_ETX;
  uint16_t desiredParent = MAX_PARENT;
  uint16_t VERSION = 0;
  uint16_t nodeEtx = 10;
  uint32_t nodeLatency;
  uint8_t MAX_RANK_INCREASE = 0;

  uint8_t etxConstraint;
  uint32_t latencyConstraint;
  bool hasConstraint[2] = {FALSE,FALSE}; //hasConstraint[0] represents ETX, hasConstraint[1] represent Latency
  
  struct in6_addr DODAGID;
  struct in6_addr DODAG_MAX;
  uint8_t typeID; //which metric
  uint32_t myQDelay = 1.0;
  bool hasOF = FALSE;
  uint8_t Prf = 0xFF;
  uint8_t alpha; //configuration parameter
  uint8_t beta;
  bool ignore = FALSE;

  struct ip6_hdr *prev_iph;
  void *prev_payload;
  struct ip6_metadata *prev_meta;
  struct dio_base_t *prev_dio;

  void resetValid();
  void chooseDesired();

  bool compare_ipv6(struct in6_addr *node1, struct in6_addr *node2) { //done
    return !memcmp(node1, node2, sizeof(struct in6_addr));
  }

  command error_t StdControl.start() { //initialization
    uint8_t indexset;

    DODAG_MAX.s6_addr16[7] = htons(0);

    memcpy(&DODAGID, &DODAG_MAX, sizeof(struct in6_addr));

    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      parentSet[indexset].valid = FALSE;
    }
    return SUCCESS;
  }

  command error_t StdControl.stop() { 
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

  uint8_t getParent(struct in6_addr node);
  
  // return the rank of the specified IP addr
  command uint8_t RPLRankInfo.getRank(struct in6_addr node){ //done
    
    uint8_t indexset;
    struct in6_addr my_addr;
    call IPAddress.getLLAddr(&my_addr);
    if(compare_ipv6(&my_addr, &node)){
      return nodeRank;
    }
    indexset = getParent(node);
    if (indexset != MAX_PARENT){
      return parentSet[indexset].rank;
    }

    return nodeRank;
  }

  bool exceedThreshold(uint8_t indexset, uint8_t ID) { //done
    return parentSet[indexset].etx_hop > ETX_THRESHOLD;
  }

  command bool RPLRankInfo.compareAddr(struct in6_addr *node1, struct in6_addr *node2){ //done
    return compare_ipv6(node1, node2);
  }

  //return the index of parent
  uint8_t getParent(struct in6_addr node) { //done
    uint8_t indexset;
    if(parentNum == 0){
      return MAX_PARENT;
    }
    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      if (compare_ipv6(&(parentSet[indexset].parentIP),&node) && parentSet[indexset].valid)
	return indexset;
    }
    return MAX_PARENT;
  }

  // return if IP is in parent set
  command bool RPLRankInfo.isParent(struct in6_addr node) { //done
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
  command void RPLRankInfo.inconsistencyDetected(struct in6_addr node){ //done
    parentNum = 0;
    nodeRank = INFINITE_RANK;
    minMetric = MAX_ETX;
    desiredParent = MAX_PARENT;
    resetValid();

    //parentNum = 0;
    //resetValid();
  }

  // ping rank component if there are parents
  command uint8_t RPLRankInfo.hasParent(){ //done
    return (parentNum);
  }

  command struct in6_addr RPLRankInfo.nextHop(struct in6_addr destination){
    //int indexset;
    struct in6_addr empty;
    empty.s6_addr16[7] = htons(0);

    if (parentNum) {
      return parentSet[desiredParent].parentIP;
    }
    return empty;
  }

  command bool RPLRankInfo.isLeaf(){ //done
    //return TRUE;
    return leafState;
  }

  command uint16_t RPLRankInfo.getEtx(){ //done
    return nodeEtx;
  }

  void insertParent(parent_t parent) {//done
    uint8_t indexset;
    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      if (!parentSet[indexset].valid) {
	parentSet[indexset] = parent;
	parentNum++;
	break;
      }
    }
  }

  void evictParent(uint8_t indexset) {//done
    parentSet[indexset].valid = FALSE;
    parentNum--;
    if (parentNum == 0) {
      //should do something
      call RouteInfo.resetTrickle();
    }
  }

  //check and remove parents on rank change
  void evictAll() {//done
    uint8_t indexset;
    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      if (parentSet[indexset].valid && parentSet[indexset].rank >= nodeRank) {
	parentSet[indexset].valid = FALSE;
	parentNum--;
      }
    }
  }

  command void RPLRankInfo.setQueuingDelay(uint32_t delay){    
    myQDelay = delay;
  }

  void recaRank() {
    uint8_t divideRank = 10;
    uint16_t prevEtx, prevRank;

    prevEtx = nodeEtx;
    prevRank = nodeRank;

    nodeEtx = parentSet[desiredParent].etx_hop + parentSet[desiredParent].etx;
    nodeRank = nodeEtx / divideRank;

    if(nodeRank == 1 && prevRank != 0){
      nodeRank = prevRank;
      nodeEtx = prevEtx;
    }

    // did the node rank get worse than the limit? 
    if(nodeRank > prevRank && nodeRank-prevRank > MAX_RANK_INCREASE && MAX_RANK_INCREASE != 0){
      // this is inconsistency!
      call RouteInfo.inconsistency();
    }
    
  }


  command void RPLRankInfo.linkResult(struct in6_addr node, uint8_t etx_now){// Compute ETX!
    uint8_t indexset;

    if(nodeRank == 1){ //root
      return;
    }

    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      if (parentSet[indexset].valid && compare_ipv6(&(parentSet[indexset].parentIP),&node))
	break;
    }

    if (indexset != MAX_PARENT) {

      parentSet[indexset].etx_hop = (parentSet[indexset].etx_hop * 5 + etx_now * 10 * 5) / 10;

      if (exceedThreshold(indexset, typeID)) {
	evictParent(indexset);
	if (indexset == desiredParent && parentNum > 0)
	  chooseDesired();
      }
      recaRank();

      printfUART(">> P_ETX UPDATE %d %d %d %d %d \n", indexset, parentSet[indexset].etx_hop, etx_now, ntohs(parentSet[indexset].parentIP.s6_addr16[7]), nodeRank);
      return;
    }
    //not contained in either parent set, do nothing
  }

  void chooseDesired() { //done; assert at least one valid parent
    uint8_t indexset;
    uint8_t min = 0;

    uint16_t minDesired;
    while (!parentSet[min++].valid); //choose the first valid
    min--;
      
    minDesired = parentSet[min].etx_hop + parentSet[min].etx;

    for (indexset = min + 1; indexset < MAX_PARENT; indexset++) {
      if (parentSet[indexset].valid && parentSet[indexset].etx != 0 &&
	  (parentSet[indexset].etx_hop + parentSet[indexset].etx < minDesired) ) {
	min = indexset;
	minDesired = parentSet[indexset].etx_hop + parentSet[indexset].etx;
      }
    }
    minMetric = minDesired;
    desiredParent = min;
  }
  
  bool checkConstraint(uint32_t latency, uint32_t lateCon, uint16_t etx, uint16_t etxCon, uint8_t type, uint8_t indexset) {

    if (indexset == MAX_PARENT) { //new incoming nodes
      if (hasConstraint[0])
	return (etx + 10 <= etxCon);
      else
	return TRUE;
    }else{
      if (hasConstraint[0])
	return (etx + parentSet[indexset].etx_hop <= etxCon);
      else
	return TRUE;
    }
  }


  bool compareParent(parent_t oldP, parent_t newP) { //old <= new, return true; 

    return (oldP.etx_hop+ oldP.etx) <= (newP.etx_hop + newP.etx);
  }

  void performConsCheck() {
    uint8_t indexset = 0;
    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      if (!checkConstraint(/*parentSet[indexset].latency*/0, latencyConstraint, parentSet[indexset].etx, etxConstraint, typeID, indexset)) {
	parentSet[indexset].valid = FALSE;
      }
    }
  }

  void computeRank(){ 

    struct ip6_hdr *iph = prev_iph;
    struct dio_base_t *dio = prev_dio;

    uint16_t pParentRank;
    struct in6_addr rDODAGID;
    uint16_t etx = 0xFF;
    uint32_t latency = 0xFFFF;
    parent_t tempParent;
    uint8_t parentIndex;
    uint16_t preRank;
    bool fulfillConstraint;
    uint8_t tempPrf;
    bool furtherCheck = FALSE;

    //struct dio_base_t* dio_base;
    struct dio_body_t* dio_body;
    struct dio_metric_header_t* dio_metric_header;
    struct dio_etx_t* dio_etx;
    struct dio_dodag_config_t* dio_dodag_config;
    struct dio_prefix_t* dio_prefix;
    uint8_t* newPoint;
    uint16_t trackLength = ntohs(iph->ip6_plen);

    if (nodeRank == 1) return; // I am root

    if (dio->version != VERSION && compare_ipv6(&dio->dodagID, &DODAGID)) {//new iteration
      //printfUART("new iteration!\n");
      parentNum = 0;
      VERSION = dio->version;
      nodeRank = INFINITE_RANK;
      minMetric = MAX_ETX;
      desiredParent = MAX_PARENT;
      resetValid();
    }

    if (dio->dagRank >= nodeRank && nodeRank != INFINITE_RANK /*&& getParent(iph->ip6_src) != MAX_PARENT*/) return;

    //printfUART("DIO in Rank %d %d %d %d\n", ntohs(iph->ip6_src.s6_addr16[7]), dio->dagRank, nodeRank, parentNum);


    pParentRank = dio->dagRank;
    memcpy(&rDODAGID, &dio->dodagID, sizeof(struct in6_addr)); // DODAG ID in this DIO packet (received DODAGID)
    tempPrf = dio->dag_preference;

    if (!compare_ipv6(&DODAGID, &DODAG_MAX) && !compare_ipv6(&DODAGID, &rDODAGID)) { // I have a DODAG but this packet is from a new DODAG
      if (Prf < tempPrf) {//ignore
	//printfUART("LESS PREFERENCE IGNORE \n");
	ignore = TRUE;
	return;
      }else if (Prf > tempPrf) { //move
	//printfUART("MOVE TO NEW DODAG \n");
	Prf = tempPrf;
	memcpy(&DODAGID, &rDODAGID, sizeof(struct in6_addr));
	parentNum = 0;
	VERSION = dio->version;
	nodeRank = INFINITE_RANK;
	minMetric = MAX_ETX;
	desiredParent = MAX_PARENT;
	resetValid();
      }else { //it depends
	furtherCheck = TRUE;
      }
    } else if (compare_ipv6(&DODAGID, &DODAG_MAX)) { //not belong to a DODAG yet
      //printfUART("TOTALLY NEW DODAG \n");
      Prf = tempPrf;
      memcpy(&DODAGID, &rDODAGID, sizeof(struct in6_addr));
      parentNum = 0;
      VERSION = dio->version;
      nodeRank = INFINITE_RANK;
      minMetric = MAX_ETX;
      desiredParent = MAX_PARENT;
      resetValid();
    } else { //same DODAG
      //printfUART("FROM SAME DODAG \n");
      Prf = tempPrf; //update prf
    }

    /////////////////////////////Collect data from DIOs/////////////////////////////////

    trackLength -= sizeof(struct dio_base_t);
    newPoint = (uint8_t*)(struct dio_base_t*)(dio + 1);
    dio_body = (struct dio_body_t*) newPoint;

    if(dio_body->type == 2){ // this contains a metric
      trackLength -= sizeof(struct dio_body_t);
      newPoint = (uint8_t*)(struct dio_body_t*)(dio_body + 1);
      dio_metric_header = (struct dio_metric_header_t*) newPoint;
      trackLength -= sizeof(struct dio_metric_header_t);
      if(dio_metric_header->routing_obj_type == 7){
	// in this implementation this is the etx metric
	newPoint = (uint8_t*)(struct dio_metric_header_t*)(dio_metric_header + 1);
	dio_etx = (struct dio_etx_t*) newPoint;
	trackLength -= sizeof(struct dio_etx_t);
	etx = dio_etx->etx;
	//printfUART("ETX RECV %d \n", etx);
	typeID = 7;
	newPoint = (uint8_t*)(struct dio_etx_t*)(dio_etx + 1);
	leafState = FALSE;
      }else{
	leafState = TRUE;
      }
    }

    dio_prefix = (struct dio_prefix_t*) newPoint;
    if(trackLength > 0 && dio_prefix->type == 3){
      trackLength -= sizeof(struct dio_prefix_t);
      if(ignore == FALSE){
	// New Prefix!!!!
	// TODO: Save prefix somewhere and make it a searchable command
      }
    }

    dio_dodag_config = (struct dio_dodag_config_t*) newPoint;
    if(trackLength > 0 && dio_dodag_config->type == 4){
      // this is configuration header
      trackLength -= sizeof(struct dio_dodag_config_t);
      if (ignore == FALSE){
	MAX_RANK_INCREASE = dio_dodag_config->MaxRankInc;
	call RouteInfo.setDODAGConfig(dio_dodag_config->DIOIntDoubl, dio_dodag_config->DIOIntMin, 
				      dio_dodag_config->DIORedun, dio_dodag_config->MaxRankInc, dio_dodag_config->MinHopRankInc);
      }
      //printfUART("CONFIGURATION! %d \n", trackLength)
    }

    ///////////////////////////////////////////////////////////////////////////////////

    //start processing

    if ((parentIndex = getParent(iph->ip6_src)) != MAX_PARENT) { //exist parent
      //printfUART("Existing parent \n");
      fulfillConstraint = checkConstraint(latency, latencyConstraint, etx, etxConstraint, typeID, parentIndex);
      if ((pParentRank >= nodeRank || !fulfillConstraint) && parentIndex == desiredParent) { //desired parent needs to be modified
	evictParent(parentIndex);
	if (parentNum != 0) {
	  chooseDesired();
	  preRank = nodeRank;
	  recaRank();
	  evictAll();
	}
	else {
	  //notify the upper module
	}
      } else if (pParentRank >= nodeRank || !fulfillConstraint) { //not desired parent, just delete it
	//printfUART("just delete \n");
	evictParent(parentIndex);
      } else {//valid parents
	if (furtherCheck) {
	  furtherCheck = FALSE;
	  memcpy(&tempParent.parentIP, &iph->ip6_src, sizeof(struct in6_addr));
	  tempParent.etx = etx;
	  //tempParent.latency = latency;
	  //tempParent.successNum = parentSet[parentIndex].successNum;
	  //tempParent.totalNum = parentSet[parentIndex].totalNum;
	  tempParent.etx_hop = parentSet[parentIndex].etx_hop;
	  tempParent.valid = TRUE;
	  tempParent.rank = pParentRank;

	  if (parentIndex == desiredParent) { // my desired parent changed its DODAG and gave me a new DODAG
	    evictParent(parentIndex);
	    if (parentNum != 0) {
	      chooseDesired();
	      if (!compareParent(parentSet[desiredParent], tempParent)) {
		Prf = tempPrf;
		memcpy(&DODAGID, &rDODAGID, sizeof(struct in6_addr));
		parentNum = 0;
		VERSION = dio->version;
		minMetric = MAX_ETX;
		desiredParent = MAX_PARENT;
		resetValid();
		insertParent(tempParent);
		chooseDesired();
		recaRank();
	      }
	      //do nothing
	      else {
		ignore = TRUE;
	      }
	    } else {
	      Prf = tempPrf;
	      memcpy(&DODAGID, &rDODAGID, sizeof(struct in6_addr));
	      parentNum = 0;
	      VERSION = dio->version;
	      minMetric = MAX_ETX;
	      desiredParent = MAX_PARENT;
	      resetValid();
	      insertParent(tempParent);
	      chooseDesired();
	      recaRank();
	    }
	  } else {
	    if (!compareParent(parentSet[desiredParent], tempParent)) {
	      Prf = tempPrf;
	      memcpy(&DODAGID, &rDODAGID, sizeof(struct in6_addr));
	      parentNum = 0;
	      VERSION = dio->version;
	      minMetric = MAX_ETX;
	      desiredParent = MAX_PARENT;
	      resetValid();
	      insertParent(tempParent);
	      chooseDesired();
	      recaRank();
	    } else {
	      ignore = TRUE;
	    }
	  }
	} else {  // just the old DODAG
	  //printfUART("just the old \n");
	  parentSet[parentIndex].rank = pParentRank; //update rank
	  parentSet[parentIndex].etx = etx;
	  //parentSet[parentIndex].latency = latency;
	  chooseDesired();
	  preRank = nodeRank;
	  recaRank();
	  evictAll();
	}
      }
    } 
    else {// new parent
      
      fulfillConstraint = checkConstraint(latency, latencyConstraint, etx, etxConstraint, typeID, parentIndex);
      
      if (pParentRank < nodeRank && fulfillConstraint && parentNum < MAX_PARENT) { // add as new parent if we have space
	memcpy(&tempParent.parentIP, &iph->ip6_src, sizeof(struct in6_addr)); //may be not right!!!
	tempParent.rank = pParentRank;
	tempParent.etx_hop = INIT_ETX;
	//printfUART("New parent %d %d %d\n", ntohs(iph->ip6_src.s6_addr16[7]), tempParent.etx_hop, parentNum);
	tempParent.valid = TRUE;
	tempParent.etx = etx;
	//printfUART("New NODE %d %d %d %d \n", fulfillConstraint, parentNum, furtherCheck, compareParent(parentSet[desiredParent], tempParent));
	
	if (parentNum != MAX_PARENT) {
	  
	  if (furtherCheck) { // new DODAG
	    
	    furtherCheck = FALSE;
	    
	    if (!compareParent(parentSet[desiredParent], tempParent)) {
	      Prf = tempPrf;
	      memcpy(&DODAGID, &rDODAGID, sizeof(struct in6_addr));
	      parentNum = 0;
	      VERSION = dio->version;
	      minMetric = MAX_ETX;
	      desiredParent = MAX_PARENT;
	      resetValid();
	      insertParent(tempParent);
	      chooseDesired();
	      recaRank();
	    }
	    else {
	      ignore = TRUE;
	    }
	  } else { // from current DODAG
	    //printfUART("Same DODAG \n");
	    insertParent(tempParent);
	    chooseDesired();
	    
	    preRank = nodeRank;
	    
	    recaRank();
	    evictAll();
	  }
	}
      }
    }
    furtherCheck = FALSE;
    performConsCheck();
  }

  command error_t IPLower.send(struct ieee154_frame_addr *next_hop, struct ip6_packet *msg, void* data){
    return call SubIPLower.send(next_hop, msg, (void*) data);
  }

  event void SubIPLower.recv(struct ip6_hdr *iph, void *payload, struct ip6_metadata *meta){

    struct dio_base_t *dio;
    struct dis_base_t *dis;

    uint8_t code; // get the code to distinguish dis and dio
    uint8_t next = iph->ip6_nxt;

    dio = (struct dio_base_t *) payload;
    dis = (struct dis_base_t *) payload;
    code = dio->icmpv6.code;

    //printfUART("I GOT %d %d!!\n", next, code);

    if(next == IANA_ICMP){
      if(code == ICMPV6_CODE_DIS){
	signal IPLower.recv(iph, payload, meta);
      }else if(code == ICMPV6_CODE_DIO){
	prev_iph = iph;
	prev_payload = payload;
	prev_meta = meta;
	prev_dio = dio;
	computeRank();
	//leafState = FALSE;
	if(nodeRank > dio->dagRank){
	  if(!ignore){
	    signal IPLower.recv(iph, payload, meta);
	  }
	  ignore = FALSE;
	}
      }else if(code == ICMPV6_CODE_DAO){
	signal DAOSend.recvDAO(iph, payload, meta);
      }
    }else{
      // this data comes from the forwarding engine
      //printfUART("recving data\n");
      signal RPLForwardingSend.recvPacket(iph, payload, meta);
    }
  }

  command error_t RPLForwardingSend.sendPacket(struct ieee154_frame_addr *next_hop, struct ip6_packet *msg, void* data){
    call Leds.led1Toggle();
    return call IPLower.send(next_hop, msg, (void*) data);
  }

  command error_t DAOSend.sendDAO(struct ieee154_frame_addr *next_hop, struct ip6_packet *msg, void* data){
    return call IPLower.send(next_hop, msg, (void*) data);
  }

  event void SubIPLower.sendDone(struct send_info *status){
    struct in6_addr* addr = status->upper_data;

    if(addr->s6_addr[0] == 0xff && ((addr->s6_addr[1] & 0xf) <= 0x3)){
      // this packet was a bcast
      return;
    }

    call RPLRankInfo.linkResult(*addr, status->link_transmissions);
  }

 default event void DAOSend.recvDAO(struct ip6_hdr *iph, void *payload, struct ip6_metadata *meta) {}
 default event void RPLForwardingSend.recvPacket(struct ip6_hdr *iph, void *payload, struct ip6_metadata *meta) {}
 default event void IPLower.recv(struct ip6_hdr *iph, void *payload, struct ip6_metadata *meta) {}


}
