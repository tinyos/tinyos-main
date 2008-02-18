
#define CC2420_DEF_RFPOWER 1
#define MAX_TABLE_SIZE 10
//#define DYMO_MONITORING

configuration TestC {

}

implementation {
  components TestM, DymoNetworkC;
  components MainC, LedsC, new TimerMilliC();

  TestM.Boot  -> MainC;
  TestM.Leds  -> LedsC;
  TestM.Timer -> TimerMilliC;
  TestM.SplitControl -> DymoNetworkC;
  TestM.Packet       -> DymoNetworkC;
  TestM.MHPacket     -> DymoNetworkC;
  TestM.Receive      -> DymoNetworkC.Receive[1];
  TestM.Intercept    -> DymoNetworkC.Intercept[1];
  TestM.MHSend       -> DymoNetworkC.MHSend[1];

#ifdef DYMO_MONITORING
  TestM.DymoMonitor -> DymoNetworkC;
#endif
}
