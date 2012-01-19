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
 * RPLRankP.nc
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

#include <RPL.h>
#include <lib6lowpan/ip.h>
#include <lib6lowpan/iovec.h>
#include <lib6lowpan/ip_malloc.h>
#include <lib6lowpan/lib6lowpan.h>

#include "blip_printf.h"
#include "IPDispatch.h"

module RPLRankP{
  provides{
    interface RPLRank as RPLRankInfo;
    interface StdControl;
    interface IP as IP_DIO_Filter;
    interface RPLParentTable;
  }
  uses {
    interface IP as IP_DIO;
    interface IPPacket;
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
  uint16_t VERSION = 0;
  uint16_t nodeEtx = divideRank;
  uint16_t MAX_RANK_INCREASE = 1;
  //uint16_t MIN_HOP_RANK_INCREASE = 1;
  
  uint8_t etxConstraint;
  uint32_t latencyConstraint;
  // hasConstraint[0] represents ETX, hasConstraint[1] represent Latency
  bool hasConstraint[2] = {FALSE,FALSE}; 
  
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
  bool ROOT = FALSE;
  bool m_running = FALSE;
  parent_t parentSet[MAX_PARENT];

  void resetValid();
  void getNewRank();


#define RPL_GLOBALADDR
#define compare_ipv6(node1, node2) \
 (!memcmp((node1), (node2), sizeof(struct in6_addr)))

  command error_t StdControl.start() { //initialization
    uint8_t indexset;

    DODAG_MAX.s6_addr16[7] = htons(0);

    ip_memcpy((uint8_t*)&DODAGID, 
              (uint8_t*)&DODAG_MAX, 
              sizeof(struct in6_addr));

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

  command parent_t* RPLParentTable.get(uint8_t i) {
    return &parentSet[i];
  }

  // declare the I am the root
  command void RPLRankInfo.declareRoot() {
    ROOT = TRUE;
    // minMetric = divideRank;
    nodeRank = ROOT_RANK;
  }

  command bool RPLRankInfo.isRoot() {
    return ROOT;
  }

  command bool RPLRankInfo.validInstance(uint8_t instanceID) {
    return TRUE;
  }

  // I am no longer a root
  command void RPLRankInfo.cancelRoot() {
  }

  uint8_t getParent(struct in6_addr *node);
  
  // return the rank of the specified IP addr
  command uint16_t RPLRankInfo.getRank(struct in6_addr *node) {
    uint8_t indexset;
    struct in6_addr my_addr;

#ifdef RPL_GLOBALADDR
    call IPAddress.getGlobalAddr(&my_addr);
#else
    call IPAddress.getLLAddr(&my_addr);
#endif

    if (compare_ipv6(&my_addr, node)) {

      if (ROOT) {
	nodeRank = ROOT_RANK;
      }
      return nodeRank;
    }

    indexset = getParent(node);

    if (indexset != MAX_PARENT) {
      return parentSet[indexset].rank;
    }

    return 0x1234;
  }

  command error_t RPLRankInfo.getDefaultRoute(struct in6_addr *next) {
    // printf_in6addr(&parentSet[desiredParent].parentIP);
    // printf("\n");
    if (parentNum) {
      ip_memcpy((uint8_t*)next, 
                (uint8_t*)call RPLOF.getParent(), 
                sizeof(struct in6_addr));
      return SUCCESS;
    }
    return FAIL;
  }

  bool exceedThreshold(uint8_t indexset, uint8_t ID) {
    return parentSet[indexset].etx_hop > ETX_THRESHOLD;
  }

  command bool RPLRankInfo.compareAddr(struct in6_addr *node1, 
                                       struct in6_addr *node2) {
    return compare_ipv6(node1, node2);
  }

  //return the index of parent
  uint8_t getParent(struct in6_addr *node) {
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
  command bool RPLRankInfo.isParent(struct in6_addr *node) {
    return (getParent(node) != MAX_PARENT);
  }

  /*
  // new iteration has begun, all need to be cleared
  command void RPLRankInfo.notifyNewIteration() {
    parentNum = 0;
    resetValid();
  }
  */

  void resetValid() {   
    uint8_t indexset;
    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      parentSet[indexset].valid = FALSE;
    }
  }

  // inconsistency is seen for the link with IP
  // record this as part of entry in table as well
  // Other layers will report this information
  command void RPLRankInfo.inconsistencyDetected() {
    parentNum = 0;
    call RPLOF.resetRank();
    nodeRank = INFINITE_RANK;
    resetValid();
    //memcpy(&DODAGID, 0, 16);
    //call RouteInfo.inconsistency();
  }

  // ping rank component if there are parents
  command uint8_t RPLRankInfo.hasParent() {
    return parentNum;
  }

  command bool RPLRankInfo.isLeaf() {
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

  command uint16_t RPLRankInfo.getEtx() {
    return call RPLOF.getObjectValue();
  }

  void insertParent(parent_t parent) {
    uint8_t indexset;
    uint16_t tempEtx_hop;

    indexset = getPreExistingParent(&parent.parentIP);

    printf("RPL: Insert Node: %d \n", indexset);

    if (indexset != MAX_PARENT) { 
      // we have previous information
      tempEtx_hop = parentSet[indexset].etx_hop;
      parentSet[indexset] = parent;

      if (tempEtx_hop > INIT_ETX && tempEtx_hop < BLIP_L2_RETRIES) {
        tempEtx_hop = tempEtx_hop-INIT_ETX;
        if (tempEtx_hop < divideRank)
          tempEtx_hop = INIT_ETX;
      } else{
        tempEtx_hop = INIT_ETX;
      }

      parentSet[indexset].etx_hop = tempEtx_hop;
      parentNum++;
      // printf("Parent Added %d \n",parentNum);
      return;
    }

    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      if (!parentSet[indexset].valid) {
	parentSet[indexset] = parent;
	parentNum++;
	break;
      }
    }
    // printf("Parent Added 2 %d \n",parentNum);
  }

  void evictParent(uint8_t indexset) {
    parentSet[indexset].valid = FALSE;
    parentNum--;
    printf("RPL: Evict parent %d %u %u\n", 
           parentNum, parentSet[indexset].etx_hop, 
           parentSet[indexset].etx);
    if (parentNum == 0) {
      // should do something
      call RouteInfo.resetTrickle();
    }
  }

  task void newParentSearch() {
    // only called when evictAll just cleared out my current desired parent
    call RPLOF.recomputeRoutes();
    getNewRank();
  }

  /* check and remove parents on rank change */
  void evictAll() {
    uint8_t indexset, myParent;
    myParent = getParent(call RPLOF.getParent());

    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      if (parentSet[indexset].valid && parentSet[indexset].rank >= nodeRank) {
	parentSet[indexset].valid = FALSE;
	parentNum--;
	printf("RPL: Evict all %d %d %d %d\n", 
               parentNum, parentSet[indexset].rank, 
               nodeRank, htons(parentSet[indexset].parentIP.s6_addr16[7]));
	if (indexset == myParent) {
	  // i just cleared out my own parent...
	  post newParentSearch();
	  return;
	}
      }
    }
  }

  command void RPLRankInfo.setQueuingDelay(uint32_t delay) {    
    myQDelay = delay;
  }

  event bool ForwardingEvents.initiate(struct ip6_packet *pkt,
                                       struct in6_addr *next_hop) {
    uint16_t len; 
    static struct ip_iovec v;
    static rpl_data_hdr_t data_hdr;

#ifndef RPL_OF_MRHOF
    return TRUE;
#endif

    if (pkt->ip6_hdr.ip6_nxt == IANA_ICMP)
      return TRUE;

    data_hdr.ip6_ext_outer.ip6e_nxt = pkt->ip6_hdr.ip6_nxt;
    data_hdr.ip6_ext_outer.ip6e_len = 0; 

    /* well, this is actually the type */
    data_hdr.ip6_ext_inner.ip6e_nxt = RPL_HBH_RANK_TYPE; 
    data_hdr.ip6_ext_inner.ip6e_len = sizeof(rpl_data_hdr_t) - 
      offsetof(rpl_data_hdr_t, bitflag);
    data_hdr.bitflag = 0;
    data_hdr.bitflag = 0 << RPL_DATA_O_BIT_SHIFT;
    data_hdr.bitflag |= 0 << RPL_DATA_R_BIT_SHIFT;
    data_hdr.bitflag |= 0 << RPL_DATA_F_BIT_SHIFT;
    data_hdr.instance_id = call RouteInfo.getInstanceID();
    data_hdr.senderRank = nodeRank;
    pkt->ip6_hdr.ip6_nxt = IPV6_HOP;

    len = ntohs(pkt->ip6_hdr.ip6_plen);

    /* add the header */
    v.iov_base = (uint8_t*) &data_hdr;
    v.iov_len = sizeof(rpl_data_hdr_t);
    v.iov_next = pkt->ip6_data; // original upper layer goes here!
    
    /* increase length in ipv6 header and relocate beginning */
    pkt->ip6_data = &v;
    len = len + v.iov_len;
    pkt->ip6_hdr.ip6_plen = htons(len);
    return TRUE;
  }

  /**
   * Signaled by the forwarding engine for each packet being forwarded.
   *
   * If we return FALSE, the stack will drop the packet instead of
   * doing whatever was in the routing table.
   *
   */
  event bool ForwardingEvents.approve(struct ip6_packet *pkt, 
                                      struct in6_addr *next_hop) {
#ifndef RPL_OF_MRHOF
    return TRUE;
#else 
    rpl_data_hdr_t data_hdr;
    bool inconsistent = FALSE;
    uint8_t o_bit;
    uint8_t nxt_hdr = IPV6_HOP;
    int off;

    /* is there a HBH header? */
    off = call IPPacket.findHeader(pkt->ip6_data, pkt->ip6_hdr.ip6_nxt, &nxt_hdr); 
    if (off < 0) return TRUE;
    /* if there is, is there a RPL TLV option in there? */
    off = call IPPacket.findTLV(pkt->ip6_data, off, RPL_HBH_RANK_TYPE);
    if (off < 0) return TRUE;
    /* read out the rpl option */
    if (iov_read(pkt->ip6_data, 
                 off + sizeof(struct tlv_hdr), 
                 sizeof(rpl_data_hdr_t) - offsetof(rpl_data_hdr_t, bitflag), 
                 (void *)&data_hdr.bitflag) != 
        sizeof(rpl_data_hdr_t) - offsetof(rpl_data_hdr_t, bitflag))
      return TRUE;
    o_bit = (data_hdr.bitflag & RPL_DATA_O_BIT_MASK) >> RPL_DATA_O_BIT_SHIFT;
//     printf("approve test: %d %d %d %d %d \n", 
//            data_hdr.senderRank, data_hdr.instance_id, 
//            nodeRank, o_bit, call RPLRankInfo.getRank(next_hop));

    /* SDH : we'd want to dispatch on the instance id if there are
       multiple dags */

    if (data_hdr.senderRank == ROOT_RANK) {
      o_bit = 1;
      goto approve;
    }

    if (o_bit && data_hdr.senderRank > nodeRank) {
      /* loop */
      inconsistent = TRUE;
    } else if (!o_bit && data_hdr.senderRank < nodeRank) {
      inconsistent = TRUE;
    }

    if (call RPLRankInfo.getRank(next_hop) >= nodeRank) {
      /* Packet is heading down if the next_hop rank is not smaller
         than the current one (not in the parent set) */
      /* By the time I am here, it means that there is a next hop but
         if this is not in my parent set, then it should be
         downward */
      data_hdr.bitflag |= 1 << RPL_DATA_O_BIT_SHIFT;
    }

    if (inconsistent) {
      if ((data_hdr.bitflag & RPL_DATA_R_BIT_MASK) >> RPL_DATA_R_BIT_SHIFT) {
        /*  this is not the first time  */
        /*  ditch this packet! */
	call RouteInfo.inconsistency();
//         printf("NOT Approving: %d %d %d\n", 
//                data_hdr.senderRank, data_hdr.instance_id, inconsistent);
        return FALSE;
      } else {
        /* just mark it */
	data_hdr.bitflag |= 1 << RPL_DATA_R_BIT_SHIFT;
	goto approve;
      }
    }

  approve:
//     printf("Approving: %d %d %d\n", 
//            data_hdr.senderRank, data_hdr.instance_id, inconsistent);
    data_hdr.senderRank = nodeRank;
    // write back the modified data header
    iov_update(pkt->ip6_data, 
               off + sizeof(struct tlv_hdr), 
               sizeof(rpl_data_hdr_t) - offsetof(rpl_data_hdr_t, bitflag), 
               (void *)&data_hdr.bitflag);
    return TRUE;
#endif
  }

  /*  Compute ETX! */
  event void ForwardingEvents.linkResult(struct in6_addr *node, 
                                         struct send_info *info) {
    uint8_t indexset, myParent;
    uint16_t etx_now = (info->link_transmissions * divideRank) / 
      info->link_fragment_attempts;

    printf("RPL: linkResult: ");
    printf_in6addr(node);
    printf(" %d [%i] %d \n", TOS_NODE_ID, etx_now, nodeRank);

    myParent = getParent(call RPLOF.getParent());

    if (nodeRank == ROOT_RANK) {
      return;
    }

    for (indexset = 0; indexset < MAX_PARENT; indexset++) {
      if (parentSet[indexset].valid && 
          compare_ipv6(&(parentSet[indexset].parentIP), node)) {
	break;
      }
    }

    if (indexset != MAX_PARENT) { // not empty...
      parentSet[indexset].etx_hop = 
        (parentSet[indexset].etx_hop * 8 + (etx_now * 2)) / 10;

      if (exceedThreshold(indexset, METRICID)) {
	evictParent(indexset);
	if (indexset == myParent && parentNum > 0)
	  call RPLOF.recomputeRoutes();
      }
      getNewRank();

//       printf(">> P_ETX UPDATE %d %d %d %d %d %d\n", 
//              indexset, parentSet[indexset].etx_hop, 
//              etx_now, ntohs(parentSet[indexset].parentIP.s6_addr16[7]), 
//              nodeRank, parentNum);

      return;
    }
    // not contained in either parent set, do nothing
  }

  /* old <= new, return true;  */
  bool compareParent(parent_t oldP, parent_t newP) { 
    return (oldP.etx_hop + oldP.etx) <= (newP.etx_hop + newP.etx);
  }

  void getNewRank() {
    uint16_t prevRank = nodeRank;//, myParent;
    bool newParent = FALSE;

    newParent = call RPLOF.recalculateRank();
    nodeRank = call RPLOF.getRank();

//     printf("GOT new rank %d %d %d\n", 
//            TOS_NODE_ID, call RPLOF.getRank(), newParent);

    if (newParent) {
      minRank = nodeRank;
      return;
    }

    if (nodeRank < minRank) {
      minRank = nodeRank;
      return;
    }

    // did the node rank get worse than the limit?
    if ((nodeRank > prevRank) && 
        (nodeRank - minRank > MAX_RANK_INCREASE) && 
        (MAX_RANK_INCREASE != 0)) {
      // this is inconsistency!
      // printf("Inconsistent %d\n", TOS_NODE_ID);
      nodeRank = INFINITE_RANK;
      minRank = INFINITE_RANK;
      call RouteInfo.inconsistency();
      return;
    }
    evictAll();
  }

  /*
   * Extract information from a received DIO message
   */
  void parseDIO(struct ip6_hdr *iph, 
                uint8_t *buf,
                int len) { 
    uint16_t pParentRank;
    struct in6_addr rDODAGID;
    uint16_t etx = 0xFFFF;
    parent_t tempParent;
    uint8_t parentIndex, myParent;
    uint16_t preRank;
    uint8_t tempPrf;
    bool newDodag = FALSE;

    struct dio_base_t *dio = (struct dio_base_t *)buf;
    struct dio_body_t* dio_body;
    struct dio_metric_header_t* dio_metric_header;
    struct dio_etx_t* dio_etx;
    struct dio_dodag_config_t* dio_dodag_config;
    // struct dio_prefix_t* dio_prefix;
    struct ip_iovec v[2];
    struct ip6_ext dummy_ext;
    int hdr_off;
    buf += sizeof(struct dio_base_t);
    len -= sizeof(struct dio_base_t);
    dummy_ext.ip6e_len = (len - 8) / 8;
    v[0].iov_len = sizeof(dummy_ext);
    v[0].iov_base = (uint8_t *)&dummy_ext;
    v[0].iov_next = &v[1];
    v[1].iov_len = len;
    v[1].iov_base = buf;
    v[1].iov_next = NULL;

    /* I am root */
    if (nodeRank == ROOT_RANK) return; 

    /* new iteration */
    if (dio->version != VERSION && compare_ipv6(&dio->dodagID, &DODAGID)) {
      parentNum = 0;
      VERSION = dio->version;
      call RPLOF.resetRank();
      nodeRank = INFINITE_RANK;
      minRank = INFINITE_RANK;
      resetValid();
    }

    // if (dio->dagRank >= nodeRank && nodeRank != INFINITE_RANK) return;

    // printf("DIO in Rank %d %d %d %d\n", 
    //        ntohs(iph->ip6_src.s6_addr16[7]), 
    //        dio->dagRank, nodeRank, parentNum);
    // printf_in6addr(&iph->ip6_src);
    // printf("\n");
    
    pParentRank = dio->dagRank;
    // DODAG ID in this DIO packet (received DODAGID)

    ip_memcpy((uint8_t *)&rDODAGID, 
              (uint8_t *)&dio->dodagID, 
              sizeof(struct in6_addr));
    tempPrf = dio->flags & DIO_PREF_MASK;

    if (!compare_ipv6(&DODAGID, &DODAG_MAX) && 
        !compare_ipv6(&DODAGID, &rDODAGID)) { 
      // I have a DODAG but this packet is from a new DODAG
      if (Prf < tempPrf) { // ignore
	// printf("LESS PREFERENCE IGNORE \n");
	ignore = TRUE;
	return;
      } else if (Prf > tempPrf) { // move
        // printf("MOVE TO NEW DODAG \n");
	Prf = tempPrf;
	ip_memcpy((uint8_t *)&DODAGID, 
                  (uint8_t *)&rDODAGID, 
                  sizeof(struct in6_addr));
	parentNum = 0;
	VERSION = dio->version;
	call RPLOF.resetRank();
	nodeRank = INFINITE_RANK;
	minRank = INFINITE_RANK;
	// desiredParent = MAX_PARENT;
	resetValid();
	newDodag = TRUE;
      } else { // it depends
        // printf("MOVE TO NEW DODAG %d %d\n",
        //        compare_ipv6(&DODAGID, &DODAG_MAX), 
        //        compare_ipv6(&DODAGID, &rDODAGID));
	newDodag = TRUE;
      }
    } else if (compare_ipv6(&DODAGID, &DODAG_MAX)) { // not belong to a DODAG yet
      //      printf("TOTALLY NEW DODAG \n");
      Prf = tempPrf;
      ip_memcpy((uint8_t *)&DODAGID, 
                (uint8_t *)&rDODAGID, 
                sizeof(struct in6_addr));
      parentNum = 0;
      VERSION = dio->version;
      call RPLOF.resetRank();
      nodeRank = INFINITE_RANK;
      minRank = INFINITE_RANK;
      //desiredParent = MAX_PARENT;
      newDodag = TRUE;
      resetValid();
    } else { // same DODAG
      //printf("FROM SAME DODAG \n");
      //Prf = tempPrf; // update prf
    }

    /////////////////////////////Collect data from DIOs/////////////////////////////////
    hdr_off = call IPPacket.findTLV(v, 0, RPL_DIO_TYPE_METRIC) - 
      sizeof(struct ip6_ext);
    // printf("RPL: metric header off: %i\n", hdr_off);
    METRICID = 0;
    OCP = 0;

    // SDH : TODO : make some #defs for DODAG constants
    if (hdr_off >= 0) {
      // have a metric header
      dio_body = (struct dio_body_t *)(buf + hdr_off);
      dio_metric_header = (struct dio_metric_header_t *)(buf + hdr_off + 2);
//       printf("metric header %i %i %i\n", 
//              dio_body->container_len, dio_metric_header->routing_obj_type,
//              dio_metric_header->object_len);
      if (dio_body->container_len >= sizeof(struct dio_metric_header_t) && 
          dio_metric_header->routing_obj_type == RPL_ROUTE_METRIC_ETX &&
          dio_metric_header->object_len == sizeof(struct dio_etx_t)) {
	// etx metric
	dio_etx = (struct dio_etx_t*)(dio_metric_header + 1);
	etx = dio_etx->etx;
        printf("RPL: ETX RECV %d \n", etx);
	METRICID = RPL_ROUTE_METRIC_ETX;
      }
    } else {
      etx = pParentRank * divideRank;
      //printf("No ETX %d \n", dio_body->type);
    }

    /* SDH : This is a routing header.  apparently we don't look at this. */
    // if (trackLength > 0 && dio_prefix->type == 3) {
    //   trackLength -= sizeof(struct dio_prefix_t);
    //   if (ignore == FALSE) {
        /* SDH : this will be a call to NeighborDiscovery */
        /* although we might want to make a PrefixManager component... */
	// New Prefix!!!!
	// TODO: Save prefix somewhere and make it a searchable command
    //   }
    // }

    /* SDH : type 4 is a configuration header. */
    hdr_off = call IPPacket.findTLV(v, 0, RPL_DIO_TYPE_DODAG) - 
      sizeof(struct ip6_ext);
    // printf("RPL: dodag header off: %i\n", hdr_off);

    if (hdr_off >= 0 && !ignore) {
      dio_dodag_config = (struct dio_dodag_config_t *)(buf + hdr_off);
      // this is configuration header

      // printf("RPL: DODAG OPT > %d %d %d %d \n", METRICID, 
      //        dio_dodag_config->type, ignore, dio_dodag_config->ocp);

      OCP = dio_dodag_config->ocp;
      MAX_RANK_INCREASE = dio_dodag_config->MaxRankInc;
      // MIN_HOP_RANK_INCREASE = dio_dodag_config->MinHopRankInc;

      call RouteInfo.setDODAGConfig(dio_dodag_config->DIOIntDoubl, 
                                    dio_dodag_config->DIOIntMin, 
                                    dio_dodag_config->DIORedun, 
                                    dio_dodag_config->MaxRankInc, 
                                    dio_dodag_config->MinHopRankInc);
      call RPLOF.setMinHopRankIncrease(dio_dodag_config->MinHopRankInc);
    }

    //////////////////////////////////////////////////////////////////////////

    // printf("PR %d NR %d OCP %d MID %d \n", 
    //        pParentRank, nodeRank, OCP, METRICID);

    // temporaily keep the parent information first
    ip_memcpy((uint8_t*)&tempParent.parentIP, 
              (uint8_t*)&iph->ip6_src, sizeof(struct in6_addr)); 
    tempParent.rank = pParentRank;
    tempParent.etx_hop = INIT_ETX;
    tempParent.valid = TRUE;
    tempParent.etx = etx;

    if ((!call RPLOF.objectSupported(METRICID) || 
        !call RPLOF.OCP(OCP)) && parentNum == 0) {
      // either I dont know the metric object or I don't support the OF
      // printf("LEAF STATE! \n");
      insertParent(tempParent);
      call RPLOF.recomputeRoutes();
      //getNewRank(); no need to compute routes when I am going to stay as a leaf!
      nodeRank = INFINITE_RANK;
      leafState = TRUE;
      return;
    }

    if ((parentIndex = getParent(&iph->ip6_src)) != MAX_PARENT) { 
      // parent already there and the rank is useful

      //printf("HOW many parents 1 ? %d %d \n", parentNum, newDodag);
      if (newDodag) {
	// old parent has to move to a new DODAG now
	if (parentNum != 0) {
	  //chooseDesired();
          // we do this to make sure that this parent is still the
          // best and it is worth moving
	  call RPLOF.recomputeRoutes(); 

	  myParent = getParent(call RPLOF.getParent());

	  if (!compareParent(parentSet[myParent], tempParent)) {
	    // the new dodag is not from my desired parent node
	    Prf = tempPrf;
	    ip_memcpy((uint8_t*)&DODAGID, 
                      (uint8_t*)&rDODAGID, 
                      sizeof(struct in6_addr));
	    parentNum = 0;
	    VERSION = dio->version;
	    resetValid();
	    insertParent(tempParent);
	    call RPLOF.recomputeRoutes();
	    getNewRank();
	  } else {
	    // I have a better node in the current DODAG so I am not moving!
	    call RPLOF.recomputeRoutes();
	    getNewRank();
	    ignore = TRUE;
	  }
	} else {
	  // not likely to happen but this is a new DODAG...
	  Prf = tempPrf;
	  ip_memcpy((uint8_t*)&DODAGID, 
                    (uint8_t*)&rDODAGID, 
                    sizeof(struct in6_addr));
	  parentNum = 0;
	  VERSION = dio->version;
	  resetValid();
	  insertParent(tempParent);
	  call RPLOF.recomputeRoutes();
	  getNewRank();
	}

      } else {
	// this DIO is just from a parent that I know already, update
	// and re-evaluate
	//	printf("known parent -- update\n");
	parentSet[parentIndex].rank = pParentRank; // update rank
	parentSet[parentIndex].etx = etx;
	call RPLOF.recomputeRoutes();
	getNewRank();
	ignore = TRUE;
      }

    } else {
      // this parent is not in my routing table
      //      printf("HOW many parents? %d \n", parentNum);

      if (parentNum > MAX_PARENT) // how do i share the parent count?
	return;

      // at this point know that its a meaningful packet from a new
      // node and we have space to store
      
      // printf("New parent %d %d %d\n", 
      //        ntohs(iph->ip6_src.s6_addr16[7]), tempParent.etx_hop, parentNum);

      if (newDodag) {
	// not only is this parent new but we have to move to a new DODAG now
	//printf("New DODAG \n");
	if (parentNum != 0) {
          // make sure that I don't have an alternative path on this DODAG
	  call RPLOF.recomputeRoutes(); 
	  myParent = getParent(call RPLOF.getParent());
	  if (!compareParent(parentSet[myParent], tempParent)) {
	    // parentIndex == desiredParent, parentNum != 0, !compareParent
	    // printf("changing DODAG\n");
	    Prf = tempPrf;
	    ip_memcpy((uint8_t *)&DODAGID, 
                      (uint8_t *)&rDODAGID, 
                      sizeof(struct in6_addr));
	    parentNum = 0;
	    VERSION = dio->version;
	    resetValid();
	    insertParent(tempParent);
	    call RPLOF.recomputeRoutes();
	    getNewRank();
	  } else {
	    // do nothing
	    ignore = TRUE;
	  }
	} else {
	  // This is the first DODAG I am registering ... or the once
	  // before are all goners already
	  // printf("First DODAG\n");
	  Prf = tempPrf;
	  ip_memcpy((uint8_t *)&DODAGID, 
                    (uint8_t *)&rDODAGID, 
                    sizeof(struct in6_addr));
	  parentNum = 0;
	  VERSION = dio->version;
	  resetValid();
	  insertParent(tempParent);
	  call RPLOF.recomputeRoutes();
	  getNewRank();
	}
      } else {
	// its a new parent from the current DODAG .. so no need for
	// DODAG configuarion just insert
	//	printf("Same DODAG %d \n", parentNum);
	insertParent(tempParent);
	call RPLOF.recomputeRoutes();
	preRank = nodeRank;
	getNewRank();
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
                         size_t len, struct ip6_metadata *meta) { 
    struct dio_base_t *dio;
    dio = (struct dio_base_t *) payload;

    if (!m_running) return;

    if (nodeRank != ROOT_RANK && dio->dagRank != 0xFFFF)
      parseDIO(iph, payload, len);

    // evict parent if the node is advertizing 0xFFFF;
    if (dio->dagRank == 0xFFFF && getParent(&iph->ip6_src) != MAX_PARENT)
      evictParent(getParent(&iph->ip6_src));

    // leafState = FALSE;
    if (nodeRank > dio->dagRank || dio->dagRank == INFINITE_RANK) {
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
