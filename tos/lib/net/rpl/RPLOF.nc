interface RPLOF {

  /* OCP for this OF */
  command bool OCP(uint16_t ocp);

  /* Which metrics does this implementation support */
  command bool objectSupported(uint16_t objectType);

  /* Current parent */
  command struct in6_addr* getParent();

  /* Current rank */
  command uint8_t getRank();
  command void resetRank();

  command bool recalcualateRank();

  /* Recompute the routes, return TRUE if rank updated */
  command bool recomputeRoutes();

}
