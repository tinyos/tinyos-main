
#include <Dip.h>

configuration DipLogicC {
  provides interface DisseminationUpdate<dip_data_t>[dip_key_t key];

  provides interface StdControl;
}

implementation {
  components DipLogicP;
  DisseminationUpdate = DipLogicP;
  StdControl = DipLogicP;

  components MainC;
  MainC.SoftwareInit -> DipLogicP;
  DipLogicP.Boot -> MainC;

  components DipTrickleMilliC;
  DipLogicP.DipTrickleTimer -> DipTrickleMilliC;

  components DipVersionC;
  DipLogicP.VersionUpdate -> DipVersionC;
  DipLogicP.DipHelp -> DipVersionC;

  components AMDipC;

  components DipDataC;
  DipLogicP.DipDataDecision -> DipDataC;
  DipDataC.DataSend -> AMDipC.DipSend;
  DipDataC.DataReceive -> AMDipC.DataReceive;
  DipDataC.DipHelp -> DipVersionC;
  DipDataC.DipEstimates -> DipLogicP;

  components DipVectorC;
  DipLogicP.DipVectorDecision -> DipVectorC;
  DipVectorC.VectorSend -> AMDipC.DipSend;
  DipVectorC.VectorReceive -> AMDipC.VectorReceive;
  DipVectorC.DipHelp -> DipVersionC;
  DipVectorC.DipEstimates -> DipLogicP;

  components DipSummaryC;
  DipLogicP.DipSummaryDecision -> DipSummaryC;
  DipSummaryC.SummarySend -> AMDipC.DipSend;
  DipSummaryC.SummaryReceive -> AMDipC.SummaryReceive;
  DipSummaryC.DipHelp -> DipVersionC;
  DipSummaryC.DipEstimates -> DipLogicP;
}
