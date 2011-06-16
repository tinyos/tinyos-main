
#include "blip_printf.h"

module RPLMRHOFP{
  provides interface RPLOF;
  uses interface ForwardingTable;
  uses interface RPLRoutingEngine as RPLRoute;
  uses interface RPLParentTable as ParentTable;
  uses interface RPLDAORoutingEngine as RPLDAO;
}
implementation{

#define STABILITY_BOUND 10
// this determines the stability bound for switching parents.
// 0 is the min value to have nodes aggressively seek new parents
// 5 or 10 is suggested

  //uint16_t minRank = INFINITE_RANK;
  uint16_t nodeRank = INFINITE_RANK;
  uint16_t minMetric = 0xFFFF;

  //#define divideRank 10

  uint32_t parentChanges = 0;
  uint16_t nodeEtx = divideRank;
  uint16_t prevParent;
  bool newParent = FALSE;
  uint16_t desiredParent = MAX_PARENT;
  uint16_t min_hop_rank_inc = 1;
  route_key_t route_key = ROUTE_INVAL_KEY;

  void setRoot(){
    nodeEtx = divideRank;
    nodeRank = ROOT_RANK;
  }

  /* OCP for MRHOF */
  command bool RPLOF.OCP(uint16_t ocp){
    if(ocp == 1)
      return TRUE;
    return FALSE;
  }

  /* Which metrics does this implementation support */
  command bool RPLOF.objectSupported(uint16_t objectType){
    if(objectType == 7){
      return TRUE;
    }

    return FALSE;
  }

  command uint16_t RPLOF.getObjectValue(){
    if(TOS_NODE_ID == RPL_ROOT_ADDR){
      setRoot();
    }

    return nodeEtx;
  }

  command void RPLOF.setMinHopRankIncrease(uint16_t val){
    min_hop_rank_inc = val;
  }

  /* Current parent */
  command struct in6_addr* RPLOF.getParent(){
    parent_t* parentNode = call ParentTable.get(desiredParent);
    return &parentNode->parentIP;
  }

  /* Current rank */
  command uint16_t RPLOF.getRank(){
    // minHopInc has to be added to this value
    return nodeRank;
  }

  command bool RPLOF.recalcualateRank(){
    // return TRUE if this is the first time that the rank is computed for this parent.

    uint16_t prevEtx, prevRank;
    parent_t* parentNode = call ParentTable.get(desiredParent);

    prevEtx = nodeEtx;
    prevRank = nodeRank;

    nodeEtx = parentNode->etx_hop + parentNode -> etx;
     // -1 because the ext computation will add at least 1
    nodeRank = (parentNode->etx_hop / divideRank * min_hop_rank_inc) + parentNode->rank;

    //printf("%d %d %d %d %d %d %d\n", desiredParent, parentNode->etx_hop, divideRank, parentNode->rank, (min_hop_rank_inc - 1), nodeRank, prevRank);

    if (nodeRank <= ROOT_RANK && prevRank > 1) {
      nodeRank = prevRank;
      nodeEtx = prevEtx;
    }

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
    uint8_t min = 0;
    uint16_t minDesired;
    parent_t* parentNode;
    //choose the first valid

    parentNode = call ParentTable.get(min);
    while(!parentNode->valid && min < MAX_PARENT){
      min++;
      parentNode = call ParentTable.get(min);
    }

    minDesired = parentNode->etx_hop + parentNode->etx;

    if (min == MAX_PARENT){ 
      call RPLOF.resetRank();
      call RPLRoute.inconsistency();
      call ForwardingTable.delRoute(route_key);
      route_key = ROUTE_INVAL_KEY;
      return FALSE;
    }

    //printf("%d %d %d %d \n", parentNode->etx, parentNode->rank, parentNode->etx_hop, min);

    parentNode = call ParentTable.get(minDesired);
    if(htons(parentNode->parentIP.s6_addr16[7]) != 0)
      minMetric = parentNode->etx_hop + parentNode->etx; // update to most recent etx

    for (indexset = min + 1; indexset < MAX_PARENT; indexset++) {
      parentNode = call ParentTable.get(indexset);
      if(parentNode->valid && parentNode->etx >= divideRank && parentNode->etx_hop >= 0 && 
	 (parentNode->etx_hop + parentNode->etx < minDesired) && parentNode->rank < nodeRank && parentNode->rank != INFINITE_RANK){
	min = indexset;
	minDesired = parentNode->etx_hop + parentNode->etx; // best aggregate end-to-end etx
	//printf("%d %d %d %d \n", parentNode->etx, parentNode->rank, parentNode->etx_hop, min);
	if(min == desiredParent)
	  minMetric = minDesired;
      }else if(min == desiredParent)
	minMetric = minDesired;
    }

    parentNode = call ParentTable.get(min);

    //printf("%d %d %d %d \n", parentNode->etx, parentNode->rank, parentNode->etx_hop, min);
    
    if(parentNode->rank > nodeRank || parentNode->rank == INFINITE_RANK){
      printf("SELECTED PARENT is FFFF %d\n", TOS_NODE_ID);
      call ForwardingTable.delRoute(route_key);
      route_key = ROUTE_INVAL_KEY;
      return FAIL;
    }

    //printf("minD %d SB %d minM %d \n", minDesired, STABILITY_BOUND, minMetric);

    if(minDesired + divideRank*STABILITY_BOUND/10 >= minMetric){ 
      // if the min measurement (minDesired) is not significantly better than the previous parent's (minMetric), stay with what we have...
      min = desiredParent;
      minDesired = minMetric;
    }

    //printf(" <> %d %d %d %d \n", parentNode->etx, parentNode->rank, parentNode->etx_hop, min);

    minMetric = minDesired;
    desiredParent = min;
    parentNode = call ParentTable.get(desiredParent);
    //printf("MRHOF %d %d %u %u\n", TOS_NODE_ID, htons(parentNode->parentIP.s6_addr16[7]), parentNode->etx_hop, parentNode->etx);

    /* set the new default route */
    /* set one of the below of maybe set both? */
    //call ForwardingTable.addRoute((const uint8_t*)&DODAGID, 128, &parentNode->parentIP, RPL_IFACE);
    route_key = call ForwardingTable.addRoute(NULL, 0, &parentNode->parentIP, RPL_IFACE); // will this give me the default path?

    if(prevParent != parentNode->parentIP.s6_addr16[7]){
      //printf(">> New Parent %d %d %lu \n", TOS_NODE_ID, htons(parentNode->parentIP.s6_addr16[7]), parentChanges++);
      printf("#L %u 0\n", (uint8_t)htons(prevParent));
      printf("#L %u 1\n", (uint8_t)htons(parentNode->parentIP.s6_addr16[7]));
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
