#include <Dip.h>

configuration AMDipC {
  provides interface DipSend;
  provides interface DipReceive as DataReceive;
  provides interface DipReceive as VectorReceive;
  provides interface DipReceive as SummaryReceive;
}

implementation {
  components AMDipP;
  components new AMSenderC(AM_DIP) as SendC;
  components new AMReceiverC(AM_DIP) as ReceiveC;

  AMDipP.NetAMSend -> SendC.AMSend;
  AMDipP.NetReceive -> ReceiveC.Receive;

  components MainC;
  MainC.SoftwareInit -> AMDipP.Init;

  DipSend = AMDipP.DipSend;
  DataReceive = AMDipP.DipDataReceive;
  VectorReceive = AMDipP.DipVectorReceive;
  SummaryReceive = AMDipP.DipSummaryReceive;
}
