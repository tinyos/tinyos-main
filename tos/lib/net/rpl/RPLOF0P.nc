module RPLOF0P{
  provides interface RPLOF;
  uses interface ForwardingTable;
}
implementation{
  uint16_t nodeRank = INFINITE_RANK;
  uint16_t minMetric = MAX_ETX;

  uint8_t divideRank = 10;
  uint32_t parentChanges = 0;
  uint8_t desiredParent;
  uint16_t nodeEtx;

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

  /* Current parent */
  command struct in6_addr* RPLOF.getParent(){
    return &parentSet[desiredParent].parentIP;
  }

  /* Current rank */
  command uint8_t RPLOF.getRank(){
    return nodeRank;
  }

  command bool RPLOF.recalcualateRank(){
    uint16_t prevEtx, prevRank;

    prevEtx = nodeEtx;
    prevRank = nodeRank;

    nodeRank = parentSet[desiredParent].rank + (parentSet[desiredParent].etx_hop / divideRank);

    if (nodeRank == 1 && prevRank != 0) {
      nodeRank = prevRank;
      nodeEtx = prevEtx;
    }
    printfUART("OF0! Rank: %d\n", nodeRank);

    return TRUE;
  }

  /* Recompute the routes, return TRUE if rank updated */
  command bool RPLOF.recomputeRoutes(){

    uint8_t indexset;
    uint8_t min = 0;
    uint16_t minDesired;
    struct in6_addr prevParent;

    //choose the first valid
    while (!parentSet[min++].valid && min < MAX_PARENT); 
    if (min == MAX_PARENT) return FALSE;

    min--;

    minDesired = parentSet[min].rank;
    for (indexset = min + 1; indexset < MAX_PARENT; indexset++) {
      if (parentSet[indexset].valid && parentSet[indexset].rank != 0xFFFF &&
	  (parentSet[indexset].rank + parentSet[indexset].etx_hop/divideRank < minDesired) ) {
	min = indexset;
	minDesired = parentSet[indexset].rank + parentSet[indexset].etx_hop/divideRank;
      }
    }

    minMetric = minDesired;
    desiredParent = min;
    /* set the new default route */
    /* set one of the below of maybe set both? */
    //call ForwardingTable.addRoute((const uint8_t*)&DODAGID, 128, &parentSet[desiredParent].parentIP, RPL_IFACE);

    call ForwardingTable.addRoute(NULL, 0, &parentSet[desiredParent].parentIP, RPL_IFACE); // will this give me the default path?

    //printfUART_in6addr(&parentSet[desiredParent].parentIP);

    if(prevParent.s6_addr16[7] != parentSet[desiredParent].parentIP.s6_addr16[7]){
      printfUART(">> New Parent %d %lu \n", TOS_NODE_ID, parentChanges++);
    }
    memcpy(&prevParent, &parentSet[desiredParent].parentIP, sizeof(struct in6_addr));

    return TRUE;
  }

  command void RPLOF.resetRank(){
    nodeRank = INFINITE_RANK;
    minMetric = MAX_ETX;
  }

}
