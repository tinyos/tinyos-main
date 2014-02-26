/* Component that abstracts which Objective Function is being used.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration RPLOFC {
  provides {
    interface RPLOF;
  }
}

implementation {

#if RPL_OF_MRHOF
  components RPLMRHOFP as RPL_OF;
#elif RPL_OF_0
  components RPLOF0P as RPL_OF;
#else
#error "You must select a RPL objective function"
#endif

  components RPLRankP;
  components RPLRoutingEngineC;
  components IPStackC;
  components RPLDAORoutingEngineC;

  RPLOF = RPL_OF.RPLOF;

  RPL_OF.ForwardingTable -> IPStackC.ForwardingTable;
  RPL_OF.RPLRoute -> RPLRoutingEngineC.RPLRoutingEngine;
  RPL_OF.ParentTable -> RPLRankP.RPLParentTable;
  RPL_OF.RPLDAO -> RPLDAORoutingEngineC.RPLDAORoutingEngine;
  RPL_OF.RPLRankInfo -> RPLRankP.RPLRankInfo;
}
