/**
 * DHV Logic Implementation.
 *
 * Define the interfaces and components.
 *
 * @author Thanh Dang
 * @author Seungweon Park
 *
 * @modified 1/3/2009   Added meaningful documentation.
 * @modified 8/28/2008  Defined DHV interfaces type.
 * @modified 8/28/2008  Took the source code from DIP.
 **/

#include <Dhv.h>

configuration DhvLogicC {
  provides interface DisseminationUpdate<dhv_data_t>[dhv_key_t key];
	provides interface DhvLogic as DataLogic;
	provides interface DhvLogic as VectorLogic;
	provides interface DhvStateLogic;
  provides interface StdControl;
}

implementation {
  components DhvLogicP;
  DisseminationUpdate = DhvLogicP;
  StdControl = DhvLogicP;
  DataLogic  = DhvLogicP.DataLogic;
	VectorLogic= DhvLogicP.VectorLogic;
	DhvStateLogic = DhvLogicP;

  components MainC;
  MainC.SoftwareInit -> DhvLogicP;
  DhvLogicP.Boot -> MainC;

  components DhvTrickleMilliC;
  DhvLogicP.DhvTrickleTimer -> DhvTrickleMilliC;

  components DhvVersionC;
  DhvLogicP.VersionUpdate -> DhvVersionC;
  DhvLogicP.DhvHelp -> DhvVersionC;
	DhvLogicP.DhvDataCache -> DhvVersionC.DataCache;
	DhvLogicP.DhvVectorCache -> DhvVersionC.VectorCache;

  components AMDhvC;

  components DhvDataC;
  DhvLogicP.DhvDataDecision -> DhvDataC;
  DhvDataC.DataSend -> AMDhvC.DhvSend;
  DhvDataC.DataReceive -> AMDhvC.DataReceive;
  DhvDataC.DhvHelp -> DhvVersionC;
  DhvDataC.DataLogic -> DhvLogicP.DataLogic;
  DhvDataC.VectorLogic -> DhvLogicP.VectorLogic;	

  components DhvVectorC;
  DhvLogicP.DhvVectorDecision -> DhvVectorC;
  DhvVectorC.VectorSend -> AMDhvC.DhvSend;
  DhvVectorC.VectorReceive -> AMDhvC.VectorReceive;
  DhvVectorC.DhvHelp -> DhvVersionC;
	DhvVectorC.VectorLogic -> DhvLogicP.VectorLogic;
	DhvVectorC.DataLogic -> DhvLogicP.DataLogic;

  components DhvSummaryC;
  DhvLogicP.DhvSummaryDecision -> DhvSummaryC;
  DhvSummaryC.SummarySend -> AMDhvC.DhvSend;
  DhvSummaryC.SummaryReceive -> AMDhvC.SummaryReceive;
  DhvSummaryC.DhvHelp -> DhvVersionC;
	DhvSummaryC.StateLogic -> DhvLogicP.DhvStateLogic;

	components DhvVBitC;
	DhvLogicP.DhvVBitDecision -> DhvVBitC;
	DhvVBitC.VBitSend -> AMDhvC.DhvSend;
	DhvVBitC.VBitReceive -> AMDhvC.DhvVBitReceive;
	DhvVBitC.DhvHelp -> DhvVersionC;
	DhvVBitC.VectorLogic -> DhvLogicP.VectorLogic;
	DhvVBitC.VBitLogic  -> DhvLogicP.DhvStateLogic;

  components DhvHSumC;
  DhvHSumC.VBitLogic -> DhvLogicP.DhvStateLogic;
  DhvHSumC.DhvHelp    -> DhvVersionC;
  DhvHSumC.HSumSend   -> AMDhvC.DhvSend;
  DhvHSumC.HSumReceive-> AMDhvC.DhvHSumReceive;
  DhvLogicP.DhvHSumDecision -> DhvHSumC;
}
