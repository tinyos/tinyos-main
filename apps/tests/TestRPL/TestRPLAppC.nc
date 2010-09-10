 #include "TestRPL.h"

configuration TestRPLAppC {}
implementation {
  components MainC, TestRPLC as App, LedsC;
  components new TimerMilliC();
  components new TimerMilliC() as Timer;
  components RandomC;
  components RPLRankC;
  components RPLRoutingEngineC;
  components IPDispatchC;
  components RPLForwardingEngineC;
  components RPLDAORoutingEngineC;

  App.Boot -> MainC.Boot;  
  App.SplitControl -> IPDispatchC;
  App.Leds -> LedsC;
  App.MilliTimer -> TimerMilliC;
  App.RPLRoute -> RPLRoutingEngineC;
  App.RootControl -> RPLRoutingEngineC;
  App.RoutingControl -> RPLRoutingEngineC;
  App.RPL -> RPLForwardingEngineC.IP[49];
  App.RPLForwardingEngine -> RPLForwardingEngineC;
  App.RPLDAO -> RPLDAORoutingEngineC;
  App.Timer -> Timer;
  App.Random -> RandomC;
}
