/**
 * Active Message Configuration.
 *
 * Define the interfaces and components.
 *
 * @author Thanh Dang
 * @author Seungweon Park
 *
 * @modified 1/3/2009   Added meaningful documentation.
 * @modified 8/28/2008  Took the source code from Dip
 **/

#include <Dhv.h>

configuration AMDhvC {
  provides interface DhvSend;
  provides interface DhvReceive as DataReceive;
  provides interface DhvReceive as VectorReceive;
  provides interface DhvReceive as SummaryReceive;
  provides interface DhvReceive as DhvVBitReceive;
  provides interface DhvReceive as DhvHSumReceive;
}

implementation {
  components AMDhvP;
  components new AMSenderC(AM_DHV) as SendC;
  components new AMReceiverC(AM_DHV) as ReceiveC;

  AMDhvP.NetAMSend -> SendC.AMSend;
  AMDhvP.NetReceive -> ReceiveC.Receive;

  components MainC;
  MainC.SoftwareInit -> AMDhvP.Init;
  AMDhvP.Boot -> MainC;

  components ActiveMessageC;
  AMDhvP.AMSplitControl -> ActiveMessageC;

  DhvSend = AMDhvP.DhvSend;
  DataReceive = AMDhvP.DhvDataReceive;
  VectorReceive = AMDhvP.DhvVectorReceive;
  SummaryReceive = AMDhvP.DhvSummaryReceive;
  DhvVBitReceive = AMDhvP.DhvVBitReceive;
  DhvHSumReceive = AMDhvP.DhvHSumReceive;

}
