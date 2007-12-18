
#include <DIP.h>

configuration DIPLogicC {
  provides interface DisseminationUpdate<dip_data_t>[dip_key_t key];

  provides interface StdControl;
}

implementation {
  components DIPLogicP;
  DisseminationUpdate = DIPLogicP;
  StdControl = DIPLogicP;

  components MainC;
  MainC.SoftwareInit -> DIPLogicP;
  DIPLogicP.Boot -> MainC;

  components DIPTrickleMilliC;
  DIPLogicP.DIPTrickleTimer -> DIPTrickleMilliC;

  components DIPVersionC;
  DIPLogicP.VersionUpdate -> DIPVersionC;
  DIPLogicP.DIPHelp -> DIPVersionC;

  components AMDIPC;

  components DIPDataC;
  DIPLogicP.DIPDataDecision -> DIPDataC;
  DIPDataC.DataSend -> AMDIPC.DIPSend;
  DIPDataC.DataReceive -> AMDIPC.DataReceive;
  DIPDataC.DIPHelp -> DIPVersionC;
  DIPDataC.DIPEstimates -> DIPLogicP;

  components DIPVectorC;
  DIPLogicP.DIPVectorDecision -> DIPVectorC;
  DIPVectorC.VectorSend -> AMDIPC.DIPSend;
  DIPVectorC.VectorReceive -> AMDIPC.VectorReceive;
  DIPVectorC.DIPHelp -> DIPVersionC;
  DIPVectorC.DIPEstimates -> DIPLogicP;

  components DIPSummaryC;
  DIPLogicP.DIPSummaryDecision -> DIPSummaryC;
  DIPSummaryC.SummarySend -> AMDIPC.DIPSend;
  DIPSummaryC.SummaryReceive -> AMDIPC.SummaryReceive;
  DIPSummaryC.DIPHelp -> DIPVersionC;
  DIPSummaryC.DIPEstimates -> DIPLogicP;
}
