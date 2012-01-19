interface RPLOF {

  /* OCP for this OF */
  command bool OCP(uint16_t ocp);

  /* Which metrics does this implementation support */
  command bool objectSupported(uint16_t objectType);

  command uint16_t getObjectValue();
  /* Current parent */
  command struct in6_addr* getParent();

  /* Current rank */
  command uint16_t getRank();
  command void resetRank();

  command bool recalculateRank();

  /* Recompute the routes, return TRUE if rank updated */
  command bool recomputeRoutes();

  command void setMinHopRankIncrease(uint16_t val);

}
