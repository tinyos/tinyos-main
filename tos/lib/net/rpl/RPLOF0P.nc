
#include "blip_printf.h"

module RPLOF0P{
  provides interface RPLOF;
  uses interface ForwardingTable;
  uses interface RPLRoutingEngine as RPLRoute;
  uses interface RPLParentTable as ParentTable;
  uses interface RPLDAORoutingEngine as RPLDAO;
}
implementation{

#define STABILITY_BOUND 5 // this determines the stability bound for switching parents.

  uint16_t nodeRank = INFINITE_RANK;
  uint16_t minMetric = 0xFFFF;
  uint16_t prevParent;

  //#define divideRank 10
  uint32_t parentChanges = 0;
  uint16_t desiredParent = MAX_PARENT;
  uint16_t nodeEtx = divideRank;
  bool newParent = FALSE;
  uint16_t min_hop_rank_inc = 1;
  route_key_t route_key = ROUTE_INVAL_KEY;

  /* OCP for OF0 */
  command bool RPLOF.OCP(uint16_t ocp){
    if(ocp == 0)
      return TRUE;
    return FALSE;
  }

  /* Which metrics does this implementation support */
  command bool RPLOF.objectSupported(uint16_t objectType){
    if(objectType == 7){
      return TRUE;
    }

    return TRUE;
  }

  command void RPLOF.setMinHopRankIncrease(uint16_t val){
    min_hop_rank_inc = val;
  }

  command uint16_t RPLOF.getObjectValue(){
    return nodeEtx;
  }

  /* Current parent */
  command struct in6_addr* RPLOF.getParent(){
    parent_t* parentNode = call ParentTable.get(desiredParent);
    return &parentNode->parentIP;
  }

  /* Current rank */
  command uint16_t RPLOF.getRank(){
    return nodeRank;
  }

  command bool RPLOF.recalcualateRank(){
    uint16_t prevEtx, prevRank;
    parent_t* parentNode = call ParentTable.get(desiredParent);

    if(desiredParent == MAX_PARENT){
      nodeRank = INFINITE_RANK;
      return FALSE;
    }

    prevEtx = nodeEtx;
    prevRank = nodeRank;

    //printf("OF0 PARENT rank %d \n", parentSet[desiredParent].rank);
    nodeEtx = parentNode->etx_hop;
    nodeRank = parentNode->rank + min_hop_rank_inc;

    if(nodeRank < min_hop_rank_inc)
      nodeRank = INFINITE_RANK;

    if(newParent){
      newParent = FALSE;
      return TRUE;
    }else{
      return FALSE;
    }
  }

  /* Recompute the routes, return TRUE if rank updated */
  command bool RPLOF.recomputeRoutes(){

    uint8_t indexset;
    uint8_t min = 0, count = 0;
    uint16_t minDesired;
    parent_t* parentNode;

    parentNode = call ParentTable.get(min);

    while(!parentNode->valid && min < MAX_PARENT && parentNode->rank != INFINITE_RANK){
      min++;
      parentNode = call ParentTable.get(min);
    }

    minDesired = parentNode->etx_hop + parentNode->rank*divideRank;

    if (min == MAX_PARENT){ 
      call RPLOF.resetRank();
      call RPLRoute.inconsistency();
      call ForwardingTable.delRoute(route_key);
      route_key = ROUTE_INVAL_KEY;
      return FALSE;
    }

    //printf("Start Compare %d %d: %d %d %d \n", htons(prevParent), htons(parentNode->parentIP.s6_addr16[7]), minDesired, parentNode->etx_hop, parentNode->rank);
    parentNode = call ParentTable.get(desiredParent);
    if(htons(parentNode->parentIP.s6_addr16[7]) != 0){
      minMetric = parentNode->etx_hop + parentNode->rank*divideRank;
      //printf("Compare %d: %d %d with %d %d\n", htons(parentNode->parentIP.s6_addr16[7]), parentNode->etx_hop, parentNode->rank, minDesired, minMetric);
    }

    if(min == desiredParent)
      minMetric = minDesired;

    for (indexset = min + 1; indexset < MAX_PARENT; indexset++) {

      parentNode = call ParentTable.get(indexset);

      //if(parentNode->valid)
	//printf("Compare %d: %d %d with %d %d\n", htons(parentNode->parentIP.s6_addr16[7]), parentNode->etx_hop, parentNode->rank, minDesired, indexset);
      if(parentNode->valid && parentNode->etx_hop >= 0 &&
	 (parentNode->etx_hop + parentNode->rank*divideRank < minDesired) && parentNode->rank < nodeRank && parentNode->rank != INFINITE_RANK){
	count ++;
	min = indexset;
	minDesired = parentNode->etx_hop + parentNode->rank*divideRank;
	//printf("Compare %d %d \n", minDesired, parentNode->etx_hop/divideRank + parentNode->rank);
	if(min == desiredParent){
	  //printf("current parent Checking...\n")
	  minMetric = minDesired;
	}
      }else if(min == desiredParent){
	minMetric = minDesired;
      }
    }

    parentNode = call ParentTable.get(min);

    if(/*parentNode->rank > nodeRank || */parentNode->rank == INFINITE_RANK){
      //printf("SELECTED PARENT is FFFF %d\n", TOS_NODE_ID);
      desiredParent = MAX_PARENT;
      call ForwardingTable.delRoute(route_key);
      route_key = ROUTE_INVAL_KEY;
      return FAIL;
    }

    if(minDesired*divideRank + STABILITY_BOUND >= minMetric*divideRank && minMetric != 0){
      // if the min measurement (minDesired) is not significantly better than the previous parent's (minMetric), stay with what we have...
      //printf("SAFETYBOUND %d %d %d\n", minDesired*divideRank, STABILITY_BOUND, minMetric*divideRank);
      min = desiredParent;
      minDesired = minMetric;
    }

    minMetric = minDesired;
    desiredParent = min;
    parentNode = call ParentTable.get(desiredParent);
    //printf("OF0 %d %d %u %u %d\n", TOS_NODE_ID, htons(parentNode->parentIP.s6_addr16[7]), parentNode->etx_hop, parentNode->rank, count);

    /* set the new default route */
    /* set one of the below of maybe set both? */
    //call ForwardingTable.addRoute((const uint8_t*)&DODAGID, 128, &parentNode->parentIP, RPL_IFACE);
    route_key = call ForwardingTable.addRoute(NULL, 0, &parentNode->parentIP, RPL_IFACE); // will this give me the default path?

    if(prevParent != parentNode->parentIP.s6_addr16[7]){
      //printf(">> New Parent %d %x %lu \n", TOS_NODE_ID, htons(parentNode->parentIP.s6_addr16[7]), parentChanges++);
      printf("#L %u 0\n", (uint8_t)htons(prevParent));
      printf("#L %u 1 %d\n", (uint8_t)htons(parentNode->parentIP.s6_addr16[7]), TOS_NODE_ID);
      newParent = TRUE;
      call RPLDAO.newParent();
    }
    prevParent = parentNode->parentIP.s6_addr16[7];

    return TRUE;

  }

  command void RPLOF.resetRank(){
    nodeRank = INFINITE_RANK;
    minMetric = 0xFFFF;
  }

}
