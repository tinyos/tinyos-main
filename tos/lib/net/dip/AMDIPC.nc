#include <DIP.h>

configuration AMDIPC {
  provides interface DIPSend;
  provides interface DIPReceive as DataReceive;
  provides interface DIPReceive as VectorReceive;
  provides interface DIPReceive as SummaryReceive;
}

implementation {
  components AMDIPP;
  components new AMSenderC(AM_DIP) as SendC;
  components new AMReceiverC(AM_DIP) as ReceiveC;

  AMDIPP.NetAMSend -> SendC.AMSend;
  AMDIPP.NetReceive -> ReceiveC.Receive;

  components MainC;
  MainC.SoftwareInit -> AMDIPP.Init;
  AMDIPP.Boot -> MainC;

  components ActiveMessageC;
  AMDIPP.AMSplitControl -> ActiveMessageC;

  DIPSend = AMDIPP.DIPSend;
  DataReceive = AMDIPP.DIPDataReceive;
  VectorReceive = AMDIPP.DIPVectorReceive;
  SummaryReceive = AMDIPP.DIPSummaryReceive;
}
