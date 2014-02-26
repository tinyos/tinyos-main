/* Interface for common operations with the Objective Function modules.
 *
 * @author JeongGil Ko (John) <jgko@cs.jhu.edu>
 * @author Brad Campbell <bradjc@umich.edu>
 */

interface RPLOF {

  /* OCP for this OF */
  command bool OCP(uint16_t ocp);
  command uint16_t getOCP();

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
