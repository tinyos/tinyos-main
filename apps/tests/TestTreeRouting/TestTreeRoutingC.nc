/* Minimal confiruation to compile TreeRoutingEngine.nc */
configuration TestTreeRoutingC {} 
implementation {
    enum {
        TREE_ROUTING_TABLE_SIZE = 12,
    };

    components MainC;
    components ActiveMessageC;
    components TestTreeRoutingP;

    components new TreeRoutingEngineP(TREE_ROUTING_TABLE_SIZE) as RE;
    //components LinkEstimatorP as LE;
    components LinkEstimatorDummyP as LE;

    TestTreeRoutingP.Boot -> MainC;
    TestTreeRoutingP.RadioControl -> ActiveMessageC;

    TestTreeRoutingP.Init -> RE;
    TestTreeRoutingP.Init -> LE;
    TestTreeRoutingP.TreeControl -> RE;

    TestTreeRoutingP.RootControl -> RE;
    

    components new AMSenderC(AM_TREE_ROUTING_CONTROL) as SubSender;  

    LE.AMSend -> SubSender;
    LE.SubPacket -> SubSender;
    LE.SubAMPacket -> SubSender;
    
   
    RE.BeaconSend -> LE.Send;
    RE.BeaconReceive -> LE.Receive;
    RE.LinkEstimator -> LE.LinkEstimator;
    RE.LinkSrcPacket -> LE.LinkSrcPacket;
    RE.AMPacket -> SubSender;
    RE.RadioControl -> ActiveMessageC;
    
    components new AMReceiverC(AM_TREE_ROUTING_CONTROL) as SubReceiver;  
    LE.SubReceive -> SubReceiver;
    
    components new TimerMilliC() as LETimer;
    LE.Timer -> LETimer;

    components new TimerMilliC() as BeaconTimer;
    RE.BeaconTimer -> BeaconTimer;

    components RandomC;
    RE.Random -> RandomC;

}
