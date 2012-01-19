/*
 * Copyright (c) 2011 Johns Hopkins University. All rights reserved.
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
 * RPLMRHOFP.nc
 * @ author JeongGil Ko (John) <jgko@cs.jhu.edu>
 */

/**
 * This file implements the IETF draft draft-ietf-roll-minrank-hysteresis-of-02
 * This file uses the ETX metric container to compute the next hop and rank 
 **/

#include "blip_printf.h"

module RPLMRHOFP{
  provides interface RPLOF;
  uses interface ForwardingTable;
  uses interface RPLRoutingEngine as RPLRoute;
  uses interface RPLParentTable as ParentTable;
  uses interface RPLDAORoutingEngine as RPLDAO;
  uses interface RPLRank as RPLRankInfo;
}
implementation{

#define STABILITY_BOUND 5
  // this determines the stability bound for switching parents.
  // 0 is the min value to have nodes aggressively seek new parents
  // 5 or 10 is suggested

  uint16_t nodeRank = INFINITE_RANK;
  uint16_t minMetric = 0xFFFF;

  uint32_t parentChanges = 0;
  uint16_t nodeEtx = divideRank;
  uint16_t prevParent;
  bool newParent = FALSE;
  uint16_t desiredParent = MAX_PARENT - 1;
  uint16_t min_hop_rank_inc = 1;
  route_key_t route_key = ROUTE_INVAL_KEY;

  void setRoot() {
    nodeEtx = divideRank;
    nodeRank = ROOT_RANK;
  }

  /* OCP for MRHOF */
  command bool RPLOF.OCP(uint16_t ocp) {
    if (ocp == RPLOF_OCP_MRHOF)
      return TRUE;
    return FALSE;
  }

  /* Which metrics does this implementation support */
  command bool RPLOF.objectSupported(uint16_t objectType) {
    if (objectType == RPL_ROUTE_METRIC_ETX) {
      return TRUE;
    }

    return FALSE;
  }

  command uint16_t RPLOF.getObjectValue() {
    if (call RPLRankInfo.isRoot()) {
      setRoot();
    }

    return nodeEtx;
  }

  command void RPLOF.setMinHopRankIncrease(uint16_t val) {
    min_hop_rank_inc = val;
  }

  /* Current parent */
  command struct in6_addr* RPLOF.getParent() {
    parent_t* parentNode = call ParentTable.get(desiredParent);
    return &parentNode->parentIP;
  }

  /* Current rank */
  command uint16_t RPLOF.getRank() {
    // minHopInc has to be added to this value
    return nodeRank;
  }

  command bool RPLOF.recalculateRank() {
    // return TRUE if this is the first time that the rank is computed
    // for this parent.

    uint16_t prevEtx, prevRank;
    parent_t* parentNode = call ParentTable.get(desiredParent);

    if (desiredParent == MAX_PARENT) {
      nodeRank = INFINITE_RANK;
      return FALSE;
    }

    prevEtx = nodeEtx;
    prevRank = nodeRank;

    nodeEtx = parentNode->etx_hop + parentNode -> etx;
    // -1 because the ext computation will add at least 1
    nodeRank = (parentNode->etx_hop / divideRank * min_hop_rank_inc) + 
      parentNode->rank;

    // printf("RPLOF: >>> %d %d %d %d %d %d %d\n", 
    //        desiredParent, parentNode->etx_hop, divideRank, 
    //        parentNode->rank, (min_hop_rank_inc - 1), nodeRank, prevRank);
    // printfflush();

    if (nodeRank <= ROOT_RANK && prevRank > 1) {
      nodeRank = prevRank;
      nodeEtx = prevEtx;
    }

    if (newParent) {
      newParent = FALSE;
      return TRUE;
    } else {
      return FALSE;
    }
  }

  /* Recompute the routes, return TRUE if rank updated */
  command bool RPLOF.recomputeRoutes() {
    uint8_t indexset;
    uint8_t min = 0;
    uint16_t minDesired;
    parent_t* parentNode, *previousParent;
    //choose the first valid

    parentNode = call ParentTable.get(min);
    while (!parentNode->valid && min < MAX_PARENT) {
      min++;
      parentNode = call ParentTable.get(min);
    }

    minDesired = parentNode->etx_hop + parentNode->etx;

    if (min == MAX_PARENT) { 
      call RPLOF.resetRank();
      call RPLRoute.inconsistency();
      // call ForwardingTable.delRoute(route_key);
      route_key = ROUTE_INVAL_KEY;
      return FALSE;
    }

    // printf("RPLOF: %d %d %d %d \n", 
    //        parentNode->etx, parentNode->rank, parentNode->etx_hop, min);

    parentNode = call ParentTable.get(desiredParent);

    // update to most recent etx
    if (htons(parentNode->parentIP.s6_addr16[7]) != 0)
      minMetric = parentNode->etx_hop + parentNode->etx; 

    for (indexset = min + 1; indexset < MAX_PARENT; indexset++) {
      parentNode = call ParentTable.get(indexset);
      if ((parentNode->valid) && 
          (parentNode->etx >= divideRank) && 
          (parentNode->etx_hop >= 0) && 
          (parentNode->etx_hop + parentNode->etx < minDesired) && 
          (parentNode->rank < nodeRank) && 
          (parentNode->rank != INFINITE_RANK)) {
	min = indexset;
        // best aggregate end-to-end etx
	minDesired = parentNode->etx_hop + parentNode->etx; 
	// printf("RPLOF: %d %d %d %d \n", 
        //        parentNode->etx, parentNode->rank, parentNode->etx_hop, min);
	if (min == desiredParent)
	  minMetric = minDesired;
      } else if (min == desiredParent) {
	minMetric = minDesired;
      }
    }

    parentNode = call ParentTable.get(min);

    if (parentNode->rank > nodeRank || parentNode->rank == INFINITE_RANK) {
      printf("RPLOF: SELECTED PARENT is FFFF %d\n", TOS_NODE_ID);
      //call ForwardingTable.delRoute(route_key);
      route_key = ROUTE_INVAL_KEY;
      return FALSE;
    }

    previousParent = call ParentTable.get(desiredParent);

    if ((minDesired + ((divideRank * STABILITY_BOUND) / 10) >= minMetric) && 
        (minMetric !=0) && 
        (previousParent->valid)) { 
      // if the min measurement (minDesired) is not significantly
      // better than the previous parent's (minMetric), stay with what
      // we have...
      min = desiredParent;
      minDesired = minMetric;
    }

    // printf("RPLOF:  <> %d %d %d %d \n", 
    //        parentNode->etx, parentNode->rank, parentNode->etx_hop, min);

    minMetric = minDesired;
    desiredParent = min;
    parentNode = call ParentTable.get(desiredParent);
    // printf("RPLOF: MRHOF %d %d %u %u\n", 
    //        TOS_NODE_ID, htons(parentNode->parentIP.s6_addr16[7]), 
    //        parentNode->etx_hop, parentNode->etx);

    /* set the new default route */
    /* set one of the below of maybe set both? */
    // call ForwardingTable.addRoute((const uint8_t*)&DODAGID, 
    // 128, &parentNode->parentIP, RPL_IFACE);
    route_key = call ForwardingTable.addRoute(NULL, 0, 
                                              &parentNode->parentIP, RPL_IFACE);

    if (prevParent != parentNode->parentIP.s6_addr16[7]) {
      // printf("RPLOF: >> New Parent %d %d %lu \n", 
      //        TOS_NODE_ID, htons(parentNode->parentIP.s6_addr16[7]), 
      //        parentChanges++);
      printf("RPLOF: #L %u 0\n", (uint8_t)htons(prevParent));
      printf("RPLOF: #L %u 1\n", (uint8_t)htons(parentNode->parentIP.s6_addr16[7]));
      newParent = TRUE;
      call RPLDAO.newParent();
    }
    prevParent = parentNode->parentIP.s6_addr16[7];

    return TRUE;
  }

  command void RPLOF.resetRank() {
    nodeRank = INFINITE_RANK;
    minMetric = 0xFFFF;
  }

  event void RPLRankInfo.parentRankChange() {}

}
