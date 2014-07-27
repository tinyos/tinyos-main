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
 * RPLOF0P.nc
 * @author JeongGil Ko (John) <jgko@cs.jhu.edu>
 */

#include "blip_printf.h"

module RPLOF0P{
  provides interface RPLOF;
  uses interface ForwardingTable;
  uses interface RPLRoutingEngine as RPLRoute;
  uses interface RPLParentTable as ParentTable;
  uses interface RPLDAORoutingEngine as RPLDAO;
  uses interface RPLRank as RPLRankInfo;
}
implementation{

  // this determines the stability bound for switching parents.
#define STABILITY_BOUND 5

  uint16_t nodeRank = INFINITE_RANK;
  uint16_t minMetric = 0xFFFF;
  uint16_t prevParent;

  uint32_t parentChanges = 0;
  uint16_t desiredParent = MAX_PARENT - 1;
  uint16_t nodeEtx = divideRank;
  bool newParent = FALSE;
  uint16_t min_hop_rank_inc = 1;
  route_key_t route_key = ROUTE_INVAL_KEY;

  /* OCP for OF0 */
  command bool RPLOF.OCP(uint16_t ocp) {
    if (ocp == RPLOF_OCP_OF0)
      return TRUE;
    return FALSE;
  }

  command uint16_t RPLOF.getOCP() {
    return RPLOF_OCP_OF0;
  }

  /* Which metrics does this implementation support */
  command bool RPLOF.objectSupported(uint16_t objectType) {
    // OF0 does not care about the metric
    return TRUE;
    /*
    if (objectType == RPL_ROUTE_METRIC_ETX) {
      return TRUE;
    }
    return FALSE;
    */
  }

  command void RPLOF.setMinHopRankIncrease(uint16_t val) {
    min_hop_rank_inc = val;
  }

  command uint16_t RPLOF.getObjectValue() {
    return nodeEtx;
  }

  /* Current parent */
  command struct in6_addr* RPLOF.getParent() {
    parent_t* parentNode = call ParentTable.get(desiredParent);
    return &parentNode->parentIP;
  }

  /* Current rank */
  command uint16_t RPLOF.getRank() {
    return nodeRank;
  }

  command bool RPLOF.recalculateRank() {
    parent_t* parentNode = call ParentTable.get(desiredParent);

    if (desiredParent == MAX_PARENT) {
      nodeRank = INFINITE_RANK;
      return FALSE;
    }

    // printf("RPLOF: OF0 PARENT rank %d \n", parentSet[desiredParent].rank);
    nodeEtx = parentNode->etx_hop;
    nodeRank = parentNode->rank + min_hop_rank_inc;

    if (nodeRank < min_hop_rank_inc)
      nodeRank = INFINITE_RANK;

    if (newParent) {
      newParent = FALSE;
      return TRUE;
    }else{
      return FALSE;
    }
  }

  /* Recompute the routes, return TRUE if rank updated */
  command bool RPLOF.recomputeRoutes() {
    uint8_t indexset;
    uint8_t min = 0, count = 0;
    uint16_t minDesired;
    parent_t* parentNode, *previousParent;

    parentNode = call ParentTable.get(min);

    while ((!parentNode->valid) &&
           (min < MAX_PARENT) &&
           (parentNode->rank != INFINITE_RANK)) {
      min++;
      parentNode = call ParentTable.get(min);
    }

    minDesired = parentNode->etx_hop + (parentNode->rank * divideRank);

    if (min == MAX_PARENT) {
      call RPLOF.resetRank();
      call RPLRoute.inconsistency();
      call ForwardingTable.delRoute(route_key);
      route_key = ROUTE_INVAL_KEY;
      return FALSE;
    }

//     printf("RPLOF: Start Compare %d %d: %d %d %d \n",
//            htons(prevParent), htons(parentNode->parentIP.s6_addr16[7]),
//            minDesired, parentNode->etx_hop, parentNode->rank);

    parentNode = call ParentTable.get(desiredParent);

    if (htons(parentNode->parentIP.s6_addr16[7]) != 0) {
      minMetric = parentNode->etx_hop + parentNode->rank*divideRank;
//       printf("RPLOF: Compare %d: %d %d with %d %d\n",
//              htons(parentNode->parentIP.s6_addr16[7]),
//              parentNode->etx_hop, parentNode->rank, minDesired, minMetric);
    }

    if (min == desiredParent)
      minMetric = minDesired;

    for (indexset = min + 1; indexset < MAX_PARENT; indexset++) {
      parentNode = call ParentTable.get(indexset);

//       if (parentNode->valid)
//         printf("RPLOF: Compare %d: %d %d with %d %d\n",
//                htons(parentNode->parentIP.s6_addr16[7]),
//                parentNode->etx_hop, parentNode->rank, minDesired, indexset);

      if ((parentNode->valid) &&
          (parentNode->etx_hop >= 0) &&
          (parentNode->etx_hop + (parentNode->rank * divideRank) < minDesired) &&
          (parentNode->rank < nodeRank) &&
          (parentNode->rank != INFINITE_RANK)) {
        count ++;
        min = indexset;
        minDesired = parentNode->etx_hop + parentNode->rank * divideRank;
//        printf("RPLOF: Compare %d %d \n",
//                minDesired, parentNode->etx_hop/divideRank + parentNode->rank);
        if (min == desiredParent) {
          // printf("RPLOF: current parent Checking...\n");
          minMetric = minDesired;
        }
      } else if (min == desiredParent) {
        minMetric = minDesired;
      }
    }

    parentNode = call ParentTable.get(min);

    /*parentNode->rank > nodeRank || */
    if (parentNode->rank == INFINITE_RANK) {
      // printf("RPLOF: SELECTED PARENT is FFFF %d\n", TOS_NODE_ID);
      desiredParent = MAX_PARENT;
      call ForwardingTable.delRoute(route_key);
      route_key = ROUTE_INVAL_KEY;
      return FALSE;
    }

    previousParent = call ParentTable.get(desiredParent);

    if ((minDesired * divideRank + STABILITY_BOUND >= minMetric * divideRank) &&
        (minMetric != 0) &&
        (previousParent->valid)) {
      // if the min measurement (minDesired) is not significantly
      // better than the previous parent's (minMetric), stay with what
      // we have...
      // printf("RPLOF: SAFETYBOUND %d %d %d\n",
      //         minDesired*divideRank, STABILITY_BOUND, minMetric*divideRank);
      min = desiredParent;
      minDesired = minMetric;
    }

    minMetric = minDesired;
    desiredParent = min;
    parentNode = call ParentTable.get(desiredParent);
    // printf("RPLOF: OF0 %d %d %u %u %d\n", TOS_NODE_ID,
    //        htons(parentNode->parentIP.s6_addr16[7]),
    //        parentNode->etx_hop, parentNode->rank, count);

    /* set the new default route */
    /* set one of the below of maybe set both? */
    // call ForwardingTable.addRoute((const uint8_t*)&DODAGID, 128,
    // l                              &parentNode->parentIP, RPL_IFACE);
    route_key = call ForwardingTable.addRoute(NULL,
                                              0,
                                              &parentNode->parentIP,
                                              RPL_IFACE);

    if (prevParent != parentNode->parentIP.s6_addr16[7]) {
      // printf("RPLOF: >> New Parent %d %x %lu \n", TOS_NODE_ID,
      //        htons(parentNode->parentIP.s6_addr16[7]),
      //        parentChanges++);
      // printf("RPLOF: #L %u 0\n", (uint8_t)htons(prevParent));
      // printf("RPLOF: #L %u 1 %d\n",
      //        (uint8_t)htons(parentNode->parentIP.s6_addr16[7]),
      //        TOS_NODE_ID);
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
